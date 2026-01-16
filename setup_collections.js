// Script to create clientes and proyectos collections
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

    // 1. Create clientes collection
    console.log('Creating clientes collection...');
    try {
        await fetch(`${BASE_URL}/collections`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                collection: 'clientes',
                meta: {
                    icon: 'business',
                    note: 'Empresas/Clientes para cotizaciones'
                },
                schema: {},
                fields: [
                    { field: 'id', type: 'integer', meta: { hidden: true, interface: 'input', readonly: true }, schema: { is_primary_key: true, has_auto_increment: true } },
                    { field: 'nombre', type: 'string', meta: { interface: 'input', required: true, width: 'full' }, schema: { is_nullable: false } },
                    { field: 'ruc', type: 'string', meta: { interface: 'input', width: 'half' }, schema: {} },
                    { field: 'direccion', type: 'text', meta: { interface: 'input-multiline', width: 'full' }, schema: {} },
                    { field: 'contacto', type: 'string', meta: { interface: 'input', width: 'half' }, schema: {} },
                    { field: 'telefono', type: 'string', meta: { interface: 'input', width: 'half' }, schema: {} },
                    { field: 'email', type: 'string', meta: { interface: 'input', width: 'half' }, schema: {} },
                    { field: 'date_created', type: 'timestamp', meta: { interface: 'datetime', readonly: true, hidden: true, special: ['date-created'] }, schema: {} }
                ]
            })
        });
        console.log('  ✓ clientes collection created');
    } catch (e) {
        console.log('  - clientes already exists or error:', e.message);
    }

    // 2. Create proyectos collection
    console.log('Creating proyectos collection...');
    try {
        await fetch(`${BASE_URL}/collections`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                collection: 'proyectos',
                meta: {
                    icon: 'folder_open',
                    note: 'Proyectos asociados a clientes'
                },
                schema: {},
                fields: [
                    { field: 'id', type: 'integer', meta: { hidden: true, interface: 'input', readonly: true }, schema: { is_primary_key: true, has_auto_increment: true } },
                    { field: 'nombre', type: 'string', meta: { interface: 'input', required: true, width: 'full' }, schema: { is_nullable: false } },
                    { field: 'ubicacion', type: 'string', meta: { interface: 'input', width: 'full' }, schema: {} },
                    { field: 'descripcion', type: 'text', meta: { interface: 'input-multiline', width: 'full' }, schema: {} },
                    { field: 'cliente_id', type: 'integer', meta: { interface: 'select-dropdown-m2o', width: 'half', special: ['m2o'] }, schema: {} },
                    { field: 'date_created', type: 'timestamp', meta: { interface: 'datetime', readonly: true, hidden: true, special: ['date-created'] }, schema: {} }
                ]
            })
        });
        console.log('  ✓ proyectos collection created');
    } catch (e) {
        console.log('  - proyectos already exists or error:', e.message);
    }

    // 3. Add relation proyectos -> clientes
    console.log('Creating relation proyectos -> clientes...');
    try {
        await fetch(`${BASE_URL}/relations`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                collection: 'proyectos',
                field: 'cliente_id',
                related_collection: 'clientes',
                meta: { one_field: 'proyectos' }
            })
        });
        console.log('  ✓ relation created');
    } catch (e) {
        console.log('  - relation error:', e.message);
    }

    // 4. Add new fields to cotizaciones
    console.log('Adding fields to cotizaciones...');
    const newFields = [
        { field: 'template_id', type: 'string', meta: { interface: 'input', width: 'half', note: 'V1-V8' }, schema: {} },
        { field: 'items_count', type: 'integer', meta: { interface: 'input', width: 'half' }, schema: {} },
        { field: 'cliente_id', type: 'integer', meta: { interface: 'select-dropdown-m2o', width: 'half', special: ['m2o'] }, schema: {} },
        { field: 'proyecto_id', type: 'integer', meta: { interface: 'select-dropdown-m2o', width: 'half', special: ['m2o'] }, schema: {} }
    ];
    
    for (const field of newFields) {
        try {
            await fetch(`${BASE_URL}/fields/cotizaciones/${field.field}`, {
                method: 'POST',
                headers,
                body: JSON.stringify(field)
            });
            console.log(`  ✓ ${field.field} added`);
        } catch (e) {
            console.log(`  - ${field.field} error:`, e.message);
        }
    }

    // 5. Add relations for cotizaciones
    console.log('Creating relations for cotizaciones...');
    try {
        await fetch(`${BASE_URL}/relations`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                collection: 'cotizaciones',
                field: 'cliente_id',
                related_collection: 'clientes'
            })
        });
        await fetch(`${BASE_URL}/relations`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                collection: 'cotizaciones',
                field: 'proyecto_id',
                related_collection: 'proyectos'
            })
        });
        console.log('  ✓ relations created');
    } catch (e) {
        console.log('  - relations error:', e.message);
    }

    // 6. Add permissions for Vendedor role
    console.log('Setting up Vendedor permissions...');
    const rolesRes = await fetch(`${BASE_URL}/roles`, { headers });
    const rolesData = await rolesRes.json();
    const vendedorRole = rolesData.data?.find(r => r.name === 'Vendedor');
    
    if (vendedorRole) {
        for (const collection of ['clientes', 'proyectos']) {
            for (const action of ['read', 'create', 'update']) {
                try {
                    await fetch(`${BASE_URL}/permissions`, {
                        method: 'POST',
                        headers,
                        body: JSON.stringify({
                            role: vendedorRole.id,
                            collection: collection,
                            action: action,
                            fields: ['*']
                        })
                    });
                } catch (e) {}
            }
        }
        console.log('  ✓ Vendedor permissions set');
    }

    console.log('\n✅ Setup complete!');
}

setup().catch(console.error);
