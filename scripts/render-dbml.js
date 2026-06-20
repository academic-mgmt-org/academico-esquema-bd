const fs = require('fs');
const path = require('path');

// Cargar el módulo instalado globalmente
let parseDMBL;
try {
    parseDMBL = require('@egomobile/dbml-renderer').parseDMBL;
} catch (e) {
    const globalPath = path.join('/home/azureuser/.npm-global/lib/node_modules/@egomobile/dbml-renderer');
    parseDMBL = require(globalPath).parseDMBL;
}

const inputPath = '/home/azureuser/docs/database_design.dbml';
const outputPath = '/home/azureuser/docs/database_design.svg';

async function main() {
    console.log(`Leyendo archivo DBML en: ${inputPath}...`);
    const dbmlContent = fs.readFileSync(inputPath, 'utf-8');

    console.log('Procesando y renderizando a formato SVG...');
    const svgOutput = await parseDMBL(dbmlContent, 'svg');

    console.log(`Escribiendo archivo SVG en: ${outputPath}...`);
    fs.writeFileSync(outputPath, svgOutput);

    console.log('[✓] Renderización SVG completada con éxito.');
}

main().catch(err => {
    console.error('[!] Error en la renderización:', err);
    process.exit(1);
});
