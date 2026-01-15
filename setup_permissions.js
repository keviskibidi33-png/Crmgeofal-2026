// Script to set permissions for cotizaciones collection
const BASE_URL = 'http://localhost:8055';

async function setup() {
    // Login as admin
    const loginRes = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email: 'admin@tuempresa.com',
            password: 'admin_password_seguro'
        })
    });
    const { data: auth } = await loginRes.json();
    const token = auth.access_token;
    
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };

    // Get all roles
    const rolesRes = await fetch(`${BASE_URL}/roles`, { headers });
    const rolesData = await rolesRes.json();
    
    // Find Vendedor role
    const vendedorRole = rolesData.data.find(r => r.name === 'Vendedor');
    
    if (vendedorRole) {
        console.log('Found Vendedor role:', vendedorRole.id);
        
        // Check existing permissions
        const permsRes = await fetch(`${BASE_URL}/permissions?filter[role][_eq]=${vendedorRole.id}`, { headers });
        const permsData = await permsRes.json();
        console.log('Existing permissions:', permsData.data?.length || 0);
        
        // Add permissions for cotizaciones if not present
        const hasCotzPerm = permsData.data?.some(p => p.collection === 'cotizaciones');
        if (!hasCotzPerm) {
            console.log('Adding permissions for cotizaciones...');
            for (const action of ['read', 'create', 'update']) {
                await fetch(`${BASE_URL}/permissions`, {
                    method: 'POST',
                    headers,
                    body: JSON.stringify({
                        role: vendedorRole.id,
                        collection: 'cotizaciones',
                        action: action,
                        fields: ['*']
                    })
                });
            }
            console.log('Permissions added!');
        }
    }

    // Test authenticated query
    console.log('\nTesting authenticated query...');
    const quotesRes = await fetch(`${BASE_URL}/items/cotizaciones?limit=5`, { headers });
    const quotesData = await quotesRes.json();
    
    if (quotesData.data) {
        console.log('Quotes found:', quotesData.data.length);
        quotesData.data.forEach(q => {
            console.log(`  - ${q.numero}-${q.year}: ${q.cliente_nombre} - S/${q.total}`);
        });
    } else {
        console.log('Error:', quotesData.errors?.[0]?.message);
    }
}

setup().catch(console.error);
