<template>
	<private-view title="Cotizador de Ventas">
		<div class="iframe-container">
			<!-- El :src inyecta tu URL + el ID del usuario actual -->
			<iframe 
				v-if="userURL"
				:src="userURL" 
				class="cotizador-frame"
				frameborder="0"
			></iframe>
		</div>
	</private-view>
</template>

<script>
import { useStores } from '@directus/extensions-sdk';
import { computed } from 'vue';

export default {
	setup() {
		const { useUserStore, useSettingsStore } = useStores();
		const userStore = useUserStore();
		const settingsStore = useSettingsStore();
		const currentUser = computed(() => userStore.currentUser);
		
		// URL del cotizador - desde el navegador del usuario (localhost:5173 en desarrollo)
		// En producción, cambiar a la URL pública del cotizador
		const BASE_URL = window.location.hostname === 'localhost' 
			? 'http://localhost:5173'
			: `${window.location.protocol}//${window.location.hostname}:5173`;
		
		const userURL = computed(() => {
			if (!currentUser.value) return null;
			// Enviamos datos del usuario para identificación
			const params = new URLSearchParams({
				user_id: currentUser.value.id,
				email: currentUser.value.email || '',
				name: `${currentUser.value.first_name || ''} ${currentUser.value.last_name || ''}`.trim()
			});
			return `${BASE_URL}?${params.toString()}`;
		});

		return { userURL };
	},
};
</script>

<style>
.iframe-container {
	width: 100%;
	height: 100%;
	padding: 0;
	overflow: hidden;
}
.cotizador-frame {
	width: 100%;
	height: calc(100vh - 100px); /* Ajuste para que no sobre espacio */
	border: none;
}
</style>
