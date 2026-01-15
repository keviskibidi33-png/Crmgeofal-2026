// Test script for quote creation and Excel saving
const API_URL = 'http://localhost:8000';

async function testQuote() {
    console.log('=== Testing Quote Creation ===\n');

    const quoteData = {
        cotizacion_numero: '001',
        cliente: 'Empresa de Prueba S.A.C.',
        ruc: '20123456789',
        contacto: 'Carlos Test',
        telefono_contacto: '999888777',
        correo: 'carlos@prueba.com',
        proyecto: 'Proyecto de Prueba',
        ubicacion: 'Lima, Perú',
        personal_comercial: 'Juan Pérez',
        telefono_comercial: '987654321',
        fecha_solicitud: '2026-01-15',
        fecha_emision: '2026-01-15',
        include_igv: true,
        igv_rate: 0.18,
        items: [
            {
                codigo: 'SRV-001',
                descripcion: 'Servicio de consultoría',
                norma: 'ISO 9001',
                acreditado: 'Sí',
                costo_unitario: 500.00,
                cantidad: 2
            },
            {
                codigo: 'SRV-002',
                descripcion: 'Análisis de laboratorio',
                norma: 'NTP 339.088',
                acreditado: 'Sí',
                costo_unitario: 150.00,
                cantidad: 5
            }
        ]
    };

    console.log('1. Sending quote to API...');
    console.log('   Items:', quoteData.items.length);
    console.log('   Client:', quoteData.cliente);

    try {
        const response = await fetch(`${API_URL}/export`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(quoteData)
        });

        if (response.ok) {
            const blob = await response.blob();
            console.log('\n2. Response received!');
            console.log('   Content-Type:', response.headers.get('content-type'));
            console.log('   File size:', (blob.size / 1024).toFixed(2), 'KB');
            
            // Save to file
            const fs = require('fs');
            const buffer = Buffer.from(await blob.arrayBuffer());
            const filename = 'test_cotizacion_output.xlsx';
            fs.writeFileSync(filename, buffer);
            console.log('   Saved to:', filename);
            
            console.log('\n3. Checking database...');
            // Check if saved in DB via Directus API
            const dbCheck = await fetch('http://localhost:8055/items/cotizaciones?limit=1&sort=-created_at');
            const dbData = await dbCheck.json();
            if (dbData.data && dbData.data.length > 0) {
                const lastQuote = dbData.data[0];
                console.log('   Latest quote in DB:');
                console.log('   - Number:', lastQuote.numero, '-', lastQuote.year);
                console.log('   - Client:', lastQuote.cliente_nombre);
                console.log('   - Total:', lastQuote.total);
                console.log('   - File path:', lastQuote.archivo_path);
            } else {
                console.log('   No quotes found in database');
            }
            
            console.log('\n=== TEST PASSED ===');
        } else {
            const error = await response.text();
            console.log('\nERROR:', response.status, error);
        }
    } catch (e) {
        console.log('\nERROR:', e.message);
    }
}

testQuote();
