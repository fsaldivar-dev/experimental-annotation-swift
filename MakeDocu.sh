#!/bin/bash

# Variables configurables
SCHEME_NAME="AnnotationSwift"
DESTINATION="generic/platform=iOS"
OUTPUT_DIR="./docs"



# Crear el directorio de salida si no existe
mkdir -p $OUTPUT_DIR

# Generar la documentación
xcodebuild docbuild \
    -scheme $SCHEME_NAME \
    -destination $DESTINATION \
    -derivedDataPath $OUTPUT_DIR \
    -allowProvisioningUpdates

# Mensaje de éxito
echo "Documentación generada en $OUTPUT_DIR"

# Buscar el archivo .doccarchive generado
DOCS_ARCHIVE=$(find $OUTPUT_DIR -name "*.doccarchive" | head -n 1)

echo "Archivo doccarchive creada en $DOCS_ARCHIVE"


if [ -z "$DOCS_ARCHIVE" ]; then
  echo "No se encontró ningún archivo .doccarchive."
  exit 1
fi

## Procesar el archivo .doccarchive
#$(xcrun --find docc) process-archive transform-for-static-hosting $DOCS_ARCHIVE --output-path $OUTPUT_DIR --hosting-base-path ''


$(xcrun --find docc) process-archive transform-for-static-hosting $DOCS_ARCHIVE --output-path ./git-page --hosting-base-path ''

if [ -d "$OUTPUT_DIR" ]; then
  rm -rf $OUTPUT_DIR
fi
echo "Documentación transformada y lista para hospedaje estático en ./git-page"


