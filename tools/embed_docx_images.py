"""Turn the linked figures in a .docx into embedded ones.

LibreOffice converts HTML to .docx with the images *linked*: the relationship
carries TargetMode="External" and an absolute file:/// path into this machine.
The document looks right here and arrives with two empty frames anywhere else,
which is not a document that can be sent to anyone.

Fixing it means rewriting three parts of the package and adding two more, and
the package is a zip - so the obvious move is to unpack it, edit, and pack it
again. That does not work. Both of the .NET routes for it, ZipFile
CreateFromDirectory and ZipArchive in Update mode, produce an archive
LibreOffice will not open: "source file could not be loaded", and nothing
further. It does so even when not a single byte of content has been changed,
which is how the archive rather than the edits was identified as the cause.
Python's zipfile writes an archive it accepts, so this one step lives here
rather than in the PowerShell that drives the rest of the build.

Called as:  embed_docx_images.py <source.docx> <output.docx>
"""

import os
import re
import sys
import zipfile
from urllib.parse import unquote

IMAGE_RELATIONSHIP = (
    r'<Relationship Id="([^"]+)" Type="[^"]*/image" '
    r'Target="([^"]+)" TargetMode="External"\s*/>'
)
INTERNAL_RELATIONSHIP = (
    '<Relationship Id="{0}" Type="http://schemas.openxmlformats.org/'
    'officeDocument/2006/relationships/image" Target="media/{1}"/>'
)


def embed(source_path, output_path):
    source = zipfile.ZipFile(source_path)
    relationships = source.read('word/_rels/document.xml.rels').decode('utf-8')
    document = source.read('word/document.xml').decode('utf-8')
    content_types = source.read('[Content_Types].xml').decode('utf-8')

    media = []
    for match in list(re.finditer(IMAGE_RELATIONSHIP, relationships)):
        identifier, target = match.group(1), match.group(2)
        local_path = unquote(target.replace('file:///', ''))
        local_path = local_path.replace('/', os.sep)
        if not os.path.isfile(local_path):
            raise SystemExit(
                'A figure the document links to is missing: ' + local_path)
        media_name = 'image%d.png' % (len(media) + 1)
        with open(local_path, 'rb') as figure:
            media.append(('word/media/' + media_name, figure.read()))
        relationships = relationships.replace(
            match.group(0), INTERNAL_RELATIONSHIP.format(identifier, media_name))
        # r:link means "fetch it from there"; r:embed means "it is in here".
        document = document.replace(
            'r:link="%s"' % identifier, 'r:embed="%s"' % identifier)

    if not media:
        raise SystemExit(
            'No linked figures were found to embed, which means the document '
            'has lost its diagrams.')

    # A .png part needs a content type or the package is rejected.
    if 'Extension="png"' not in content_types:
        content_types = re.sub(
            r'(<Types[^>]*>)',
            r'\1<Default Extension="png" ContentType="image/png"/>',
            content_types, count=1)

    rewritten = {
        'word/_rels/document.xml.rels': relationships.encode('utf-8'),
        'word/document.xml': document.encode('utf-8'),
        '[Content_Types].xml': content_types.encode('utf-8'),
    }

    # The original entry order is kept. An OPC reader is entitled to expect
    # [Content_Types].xml where the writer put it, and there is nothing to gain
    # from rearranging the rest.
    output = zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED)
    try:
        for entry in source.infolist():
            output.writestr(
                entry.filename,
                rewritten.get(entry.filename, source.read(entry.filename)))
        for name, data in media:
            output.writestr(name, data)
    finally:
        output.close()
        source.close()

    print('embedded %d figure(s)' % len(media))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    embed(sys.argv[1], sys.argv[2])
