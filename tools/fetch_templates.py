#!/usr/bin/env python3
"""Extrait quelques membres d'une archive ZIP distante sans la télécharger en entier.

Utilisé par tools/setup.sh pour récupérer seulement les templates d'export utiles (Web
mono-thread ; (bureau) Windows et Linux x86_64) dans le fichier
Godot_v<version>-stable_export_templates.tpz (1,3 Go) des releases GitHub : le serveur répond
aux requêtes HTTP Range (206), on lit donc la fin de l'archive (répertoire central), puis
uniquement les octets des membres voulus, par morceaux de 8 Mo (chacun réessayé trois fois),
décompressés au fil de l'eau : un template Windows (36 Mo compressés, 104 Mo) ne tient pas
tout entier en mémoire.

Usage :
    python3 tools/fetch_templates.py <url.tpz> <dossier_de_sortie> <motif> [<motif> ...]
    ex. motifs : 'templates/web_nothreads_*.zip' 'templates/windows_release_x86_64.exe'
                 'templates/linux_release.x86_64' 'templates/version.txt'

Les membres sont écrits à plat dans le dossier de sortie (sans le préfixe templates/).
Bibliothèque standard seulement (urllib suit HTTPS_PROXY et SSL_CERT_FILE).
Code de retour : 0 si au moins un membre a été extrait, 1 sinon.
"""

import fnmatch
import os
import struct
import sys
import time
import urllib.request
import zlib

TAIL = 1 << 16
EOCD = 0x06054B50
ZIP64_LOCATOR = 0x07064B50
ZIP64_EOCD = 0x06064B50
CENTRAL = 0x02014B50
LOCAL = 0x04034B50
CHUNK = 8 << 20
RETRIES = 3


def fetch(url, start, end):
    """Octets [start, end] inclus de l'URL (requête Range), réessayée en cas de coupure."""
    for attempt in range(RETRIES):
        req = urllib.request.Request(url, headers={"Range": "bytes=%d-%d" % (start, end)})
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                if resp.status != 206:
                    raise RuntimeError("le serveur ignore Range (HTTP %d)" % resp.status)
                data = resp.read()
            if len(data) != end - start + 1:
                raise OSError("réponse tronquée (%d octets sur %d)" % (len(data), end - start + 1))
            return data
        except OSError:
            if attempt == RETRIES - 1:
                raise
            time.sleep(2 * (attempt + 1))
    raise RuntimeError("inaccessible")


def total_size(url):
    req = urllib.request.Request(url, headers={"Range": "bytes=0-0"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        if resp.status != 206:
            raise RuntimeError("le serveur ignore Range (HTTP %d)" % resp.status)
        content_range = resp.headers.get("Content-Range", "")
        return int(content_range.rsplit("/", 1)[1])


def central_directory(url, size):
    """(offset, taille) du répertoire central, ZIP64 compris."""
    tail_start = max(0, size - TAIL)
    tail = fetch(url, tail_start, size - 1)
    pos = tail.rfind(struct.pack("<I", EOCD))
    if pos < 0:
        raise RuntimeError("fin de répertoire central introuvable")
    _, _, _, _, _, cd_size, cd_offset, _ = struct.unpack("<IHHHHIIH", tail[pos : pos + 22])
    if cd_offset == 0xFFFFFFFF or cd_size == 0xFFFFFFFF:
        loc = tail.rfind(struct.pack("<I", ZIP64_LOCATOR), 0, pos)
        if loc < 0:
            raise RuntimeError("localisateur ZIP64 introuvable")
        _, _, eocd64_offset, _ = struct.unpack("<IIQI", tail[loc : loc + 20])
        rec = fetch(url, eocd64_offset, eocd64_offset + 55)
        fields = struct.unpack("<IQHHIIQQQQ", rec[:56])
        sig, cd_size, cd_offset = fields[0], fields[8], fields[9]
        if sig != ZIP64_EOCD:
            raise RuntimeError("enregistrement ZIP64 invalide")
    return cd_offset, cd_size


def entries(data):
    """Parcourt le répertoire central : (nom, méthode, crc, taille comp., taille, offset local)."""
    pos = 0
    while pos + 46 <= len(data):
        fields = struct.unpack("<IHHHHHHIIIHHHHHII", data[pos : pos + 46])
        if fields[0] != CENTRAL:
            break
        method, crc, comp, size = fields[4], fields[7], fields[8], fields[9]
        name_len, extra_len, comment_len = fields[10], fields[11], fields[12]
        offset = fields[16]
        name = data[pos + 46 : pos + 46 + name_len].decode("utf-8", "replace")
        extra = data[pos + 46 + name_len : pos + 46 + name_len + extra_len]
        # Champ ZIP64 (0x0001) : valeurs 64 bits dans l'ordre taille, taille comp., offset.
        i = 0
        while i + 4 <= len(extra):
            tag, length = struct.unpack("<HH", extra[i : i + 4])
            if tag == 0x0001:
                values = extra[i + 4 : i + 4 + length]
                k = 0
                if size == 0xFFFFFFFF:
                    size = struct.unpack("<Q", values[k : k + 8])[0]
                    k += 8
                if comp == 0xFFFFFFFF:
                    comp = struct.unpack("<Q", values[k : k + 8])[0]
                    k += 8
                if offset == 0xFFFFFFFF:
                    offset = struct.unpack("<Q", values[k : k + 8])[0]
            i += 4 + length
        yield name, method, crc, comp, size, offset
        pos += 46 + name_len + extra_len + comment_len


def extract(url, name, method, crc, comp, size, offset, out_path):
    header = fetch(url, offset, offset + 29)
    sig, _, _, _, _, _, _, _, _, name_len, extra_len = struct.unpack("<IHHHHHIIIHH", header)
    if sig != LOCAL:
        raise RuntimeError("en-tête local invalide pour " + name)
    start = offset + 30 + name_len + extra_len
    if method not in (0, 8):
        raise RuntimeError("compression %d non gérée pour %s" % (method, name))
    inflater = zlib.decompressobj(-15) if method == 8 else None
    tmp = out_path + ".part"
    written = 0
    check = 0
    with open(tmp, "wb") as handle:
        pos, end = start, start + comp
        while pos < end:
            raw = fetch(url, pos, min(pos + CHUNK, end) - 1)
            pos += len(raw)
            data = inflater.decompress(raw) if inflater else raw
            if pos >= end and inflater:
                data += inflater.flush()
            handle.write(data)
            written += len(data)
            check = zlib.crc32(data, check)
    if written != size or (check & 0xFFFFFFFF) != crc:
        os.remove(tmp)
        raise RuntimeError("contrôle d'intégrité raté pour " + name)
    os.replace(tmp, out_path)


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 1
    url, out_dir, patterns = argv[1], argv[2], argv[3:]
    os.makedirs(out_dir, exist_ok=True)
    size = total_size(url)
    cd_offset, cd_size = central_directory(url, size)
    directory = fetch(url, cd_offset, cd_offset + cd_size - 1)
    count = 0
    for name, method, crc, comp, length, offset in entries(directory):
        if not any(fnmatch.fnmatch(name, p) for p in patterns):
            continue
        out_path = os.path.join(out_dir, os.path.basename(name))
        print("[fetch_templates] %s (%.1f Mo)" % (name, comp / 1048576.0))
        extract(url, name, method, crc, comp, length, offset, out_path)
        count += 1
    return 0 if count else 1


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except Exception as exc:  # meilleur effort : setup.sh bascule sur le téléchargement complet
        print("[fetch_templates] échec : %s" % exc, file=sys.stderr)
        sys.exit(1)
