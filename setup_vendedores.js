// Script to create Vendedor role and test users
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

    // 1. Create Vendedor role
    console.log('Creating Vendedor role...');
    const roleRes = await fetch(`${BASE_URL}/roles`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
            name: 'Vendedor',
            icon: 'badge',
            description: 'Rol para vendedores con acceso a cotizaciones',
            admin_access: false,
            app_access: true
        })
    });
    const roleData = await roleRes.json();
    const roleId = roleData.data?.id;
    console.log('Role created:', roleId);

    // 2. Set permissions for cotizaciones collection
    if (roleId) {
        console.log('Setting permissions...');
        // Read permission
        await fetch(`${BASE_URL}/permissions`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                role: roleId,
                collection: 'cotizaciones',
                action: 'read',
                fields: ['*']
            })
        });
        // Create permission
        await fetch(`${BASE_URL}/permissions`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                role: roleId,
                collection: 'cotizaciones',
                action: 'create',
                fields: ['*']
            })
        });
        // Update permission
        await fetch(`${BASE_URL}/permissions`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                role: roleId,
                collection: 'cotizaciones',
                action: 'update',
                fields: ['*']
            })
        });
        console.log('Permissions set!');

        // 3. Create test vendor users
        console.log('Creating test users...');
        const users = [
            { first_name: 'Juan', last_name: 'Pérez', email: 'juan.perez@empresa.com', password: 'vendedor123' },
            { first_name: 'María', last_name: 'García', email: 'maria.garcia@empresa.com', password: 'vendedor123' }
        ];

        for (const user of users) {
            const userRes = await fetch(`${BASE_URL}/users`, {
                method: 'POST',
                headers,
                body: JSON.stringify({
                    ...user,
                    role: roleId,
                    status: 'active'
                })
            });
            const userData = await userRes.json();
            console.log(`User created: ${user.email}`, userData.data?.id ? 'OK' : userData.errors?.[0]?.message);
        }
    }

    console.log('\n=== Setup Complete ===');
    console.log('Vendedor users:');
    console.log('  - juan.perez@empresa.com / vendedor123');
    console.log('  - maria.garcia@empresa.com / vendedor123');
}

setup().catch(console.error);
