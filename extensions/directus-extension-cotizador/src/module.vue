<template>
	<private-view title="Cotizador de Ventas">
		<template #navigation>
			<v-list nav>
				<v-list-item 
					:active="currentView === 'new'" 
					@click="currentView = 'new'"
					clickable
				>
					<v-list-item-icon><v-icon name="add_circle" /></v-list-item-icon>
					<v-list-item-content>Nueva Cotización</v-list-item-content>
				</v-list-item>
				<v-list-item 
					:active="currentView === 'list'" 
					@click="currentView = 'list'; loadQuotesFiltered()"
					clickable
				>
					<v-list-item-icon><v-icon name="list_alt" /></v-list-item-icon>
					<v-list-item-content>Historial</v-list-item-content>
				</v-list-item>
				<v-list-item v-if="isAdmin" clickable @click="openDirectusCollection">
					<v-list-item-icon><v-icon name="table_chart" /></v-list-item-icon>
					<v-list-item-content>Administrar</v-list-item-content>
				</v-list-item>
			</v-list>
		</template>
		
		<template #sidebar>
			<sidebar-detail icon="receipt_long" title="Cotizaciones Recientes">
				<div class="quotes-list">
					<div v-if="loading" class="loading">Cargando...</div>
					<div v-else-if="quotes.length === 0" class="empty">No hay cotizaciones</div>
					<div v-else>
						<div 
							v-for="quote in quotes" 
							:key="quote.id" 
							class="quote-item"
							@click="openQuote(quote)"
						>
							<div class="quote-number">{{ quote.numero }}-{{ String(quote.year).slice(-2) }}</div>
							<div class="quote-client">{{ quote.cliente_nombre || 'Sin cliente' }}</div>
							<div class="quote-total">S/ {{ formatNumber(quote.total) }}</div>
						</div>
					</div>
					<button class="refresh-btn" @click="loadQuotes">
						↻ Actualizar
					</button>
				</div>
			</sidebar-detail>
		</template>
		
		<!-- Main content area -->
		<div class="main-content">
			<!-- Nueva Cotización (iframe) -->
			<div v-if="currentView === 'new'" class="iframe-container">
				<iframe 
					v-if="userURL"
					:src="userURL" 
					class="cotizador-frame"
					frameborder="0"
				></iframe>
			</div>
			
			<!-- Historial de cotizaciones -->
			<div v-else-if="currentView === 'list'" class="history-view">
				<div class="history-header">
					<h2>Historial de Cotizaciones</h2>
				</div>
				
				<!-- Filtros -->
				<div class="filters-section">
					<div class="filter-row">
						<div class="filter-group">
							<label>Buscar:</label>
							<input 
								type="text" 
								v-model="searchText" 
								placeholder="Cliente, proyecto, número..."
								class="filter-input"
								@input="loadQuotesFiltered"
							/>
						</div>
						<div class="filter-group">
							<label>Desde:</label>
							<input type="date" v-model="dateFrom" class="filter-input" @change="loadQuotesFiltered" />
						</div>
						<div class="filter-group">
							<label>Hasta:</label>
							<input type="date" v-model="dateTo" class="filter-input" @change="loadQuotesFiltered" />
						</div>
						<div class="filter-actions">
							<button class="btn-primary" @click="loadQuotesFiltered">🔍 Buscar</button>
							<button class="btn-secondary" @click="clearFilters">✕ Limpiar</button>
							<button class="btn-download" @click="downloadReport">📥 Descargar</button>
						</div>
					</div>
				</div>
				
				<!-- Resultados -->
				<div class="results-info" v-if="filteredQuotes.length > 0">
					Mostrando {{ filteredQuotes.length }} cotizaciones
					<span v-if="totalSum > 0"> | Total: S/ {{ formatNumber(totalSum) }}</span>
				</div>
				
				<div v-if="loading" class="loading">Cargando...</div>
				<div v-else-if="filteredQuotes.length === 0" class="empty">No hay cotizaciones con estos filtros</div>
				<table v-else class="quotes-table">
					<thead>
						<tr>
							<th>N° Cotización</th>
							<th>Cliente</th>
							<th>Proyecto</th>
							<th>Total</th>
							<th>Fecha</th>
							<th>Acciones</th>
						</tr>
					</thead>
					<tbody>
						<tr v-for="quote in filteredQuotes" :key="quote.id">
							<td class="quote-num">{{ quote.numero }}-{{ String(quote.year).slice(-2) }}</td>
							<td>{{ quote.cliente_nombre || '-' }}</td>
							<td>{{ quote.proyecto || '-' }}</td>
							<td class="quote-total">S/ {{ formatNumber(quote.total) }}</td>
							<td>{{ formatDate(quote.created_at) }}</td>
							<td>
								<button class="action-btn" @click="openQuote(quote)">Ver</button>
								<button class="action-btn download" @click="downloadQuote(quote)">📥</button>
							</td>
						</tr>
					</tbody>
				</table>
			</div>
		</div>
	</private-view>
</template>

<script>
import { useStores, useApi } from '@directus/extensions-sdk';
import { computed, ref, onMounted } from 'vue';

export default {
	setup() {
		const api = useApi();
		const { useUserStore } = useStores();
		const userStore = useUserStore();
		const currentUser = computed(() => userStore.currentUser);
		
		const quotes = ref([]);
		const filteredQuotes = ref([]);
		const loading = ref(false);
		const currentView = ref('new');
		
		// Filters
		const searchText = ref('');
		const dateFrom = ref('');
		const dateTo = ref('');
		
		// Check if user is admin
		const isAdmin = computed(() => {
			const user = currentUser.value;
			if (!user) return false;
			return user.role?.admin_access || user.admin_access || false;
		});
		
		// Total sum of filtered quotes
		const totalSum = computed(() => {
			return filteredQuotes.value.reduce((sum, q) => sum + Number(q.total || 0), 0);
		});
		
		const BASE_URL = window.location.hostname === 'localhost' 
			? 'http://localhost:5173'
			: `${window.location.protocol}//${window.location.hostname}:5173`;
		
		const userURL = computed(() => {
			if (!currentUser.value) return null;
			const params = new URLSearchParams({
				user_id: currentUser.value.id,
				email: currentUser.value.email || '',
				name: `${currentUser.value.first_name || ''} ${currentUser.value.last_name || ''}`.trim(),
				phone: currentUser.value.phone || currentUser.value.telefono || ''
			});
			return `${BASE_URL}?${params.toString()}`;
		});
		
		async function loadQuotes() {
			loading.value = true;
			try {
				const response = await api.get('/items/cotizaciones', {
					params: {
						limit: 100,
						sort: ['-created_at'],
						fields: ['id', 'numero', 'year', 'cliente_nombre', 'proyecto', 'total', 'created_at', 'archivo_path']
					}
				});
				quotes.value = response.data.data || [];
				filteredQuotes.value = quotes.value;
			} catch (e) {
				console.error('Error loading quotes:', e);
				quotes.value = [];
				filteredQuotes.value = [];
			} finally {
				loading.value = false;
			}
		}
		
		function loadQuotesFiltered() {
			let result = [...quotes.value];
			
			// Filter by search text
			if (searchText.value) {
				const search = searchText.value.toLowerCase();
				result = result.filter(q => 
					(q.cliente_nombre || '').toLowerCase().includes(search) ||
					(q.proyecto || '').toLowerCase().includes(search) ||
					(q.numero || '').toLowerCase().includes(search)
				);
			}
			
			// Filter by date range
			if (dateFrom.value) {
				const from = new Date(dateFrom.value);
				result = result.filter(q => new Date(q.created_at) >= from);
			}
			if (dateTo.value) {
				const to = new Date(dateTo.value);
				to.setHours(23, 59, 59);
				result = result.filter(q => new Date(q.created_at) <= to);
			}
			
			filteredQuotes.value = result;
		}
		
		function clearFilters() {
			searchText.value = '';
			dateFrom.value = '';
			dateTo.value = '';
			filteredQuotes.value = quotes.value;
		}
		
		function downloadReport() {
			// Generate CSV from filtered quotes
			const headers = ['N° Cotización', 'Cliente', 'Proyecto', 'Total', 'Fecha'];
			const rows = filteredQuotes.value.map(q => [
				`${q.numero}-${String(q.year).slice(-2)}`,
				q.cliente_nombre || '',
				q.proyecto || '',
				formatNumber(q.total),
				formatDate(q.created_at)
			]);
			
			let csv = headers.join(',') + '\n';
			rows.forEach(row => {
				csv += row.map(cell => `"${cell}"`).join(',') + '\n';
			});
			csv += `\n"Total","","","${formatNumber(totalSum.value)}",""`;
			
			// Download
			const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
			const url = URL.createObjectURL(blob);
			const a = document.createElement('a');
			a.href = url;
			const dateStr = new Date().toISOString().slice(0, 10);
			a.download = `cotizaciones_${dateStr}.csv`;
			a.click();
			URL.revokeObjectURL(url);
		}
		
		function downloadQuote(quote) {
			if (quote.archivo_path) {
				window.open(`http://localhost:8000/download/${quote.year}/${quote.numero}`, '_blank');
			} else {
				alert('No hay archivo disponible para esta cotización');
			}
		}
		
		function formatNumber(num) {
			return Number(num || 0).toFixed(2);
		}
		
		function formatDate(dateStr) {
			if (!dateStr) return '-';
			const d = new Date(dateStr);
			return d.toLocaleDateString('es-PE', { day: '2-digit', month: '2-digit', year: 'numeric' });
		}
		
		function openQuote(quote) {
			window.open(`/admin/content/cotizaciones/${quote.id}`, '_blank');
		}
		
		function openDirectusCollection() {
			window.location.href = '/admin/content/cotizaciones';
		}
		
		onMounted(() => {
			loadQuotes();
		});

		return { 
			userURL, quotes, filteredQuotes, loading, currentView, isAdmin, totalSum,
			searchText, dateFrom, dateTo,
			loadQuotes, loadQuotesFiltered, clearFilters, downloadReport, downloadQuote,
			formatNumber, formatDate, openQuote, openDirectusCollection 
		};
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
	height: calc(100vh - 100px);
	border: none;
}
.quotes-list {
	padding: 8px;
}
.quote-item {
	padding: 10px;
	margin-bottom: 8px;
	background: var(--background-normal);
	border-radius: 6px;
	cursor: pointer;
	transition: background 0.2s;
}
.quote-item:hover {
	background: var(--background-normal-alt);
}
.quote-number {
	font-weight: 600;
	color: var(--primary);
}
.quote-client {
	font-size: 12px;
	color: var(--foreground-subdued);
	margin-top: 2px;
}
.quote-total {
	font-size: 13px;
	font-weight: 500;
	margin-top: 4px;
}
.loading, .empty {
	text-align: center;
	padding: 20px;
	color: var(--foreground-subdued);
}
.refresh-btn {
	width: 100%;
	padding: 8px;
	margin-top: 10px;
	background: var(--background-normal);
	border: 1px solid var(--border-normal);
	border-radius: 4px;
	cursor: pointer;
	color: var(--foreground-normal);
}
.refresh-btn:hover {
	background: var(--background-normal-alt);
}
.main-content {
	height: 100%;
	overflow: auto;
}
.history-view {
	padding: 20px;
}
.history-header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-bottom: 20px;
}
.history-header h2 {
	margin: 0;
	color: var(--foreground-normal);
}
.refresh-btn-main {
	padding: 8px 16px;
	background: var(--primary);
	color: white;
	border: none;
	border-radius: 4px;
	cursor: pointer;
}
.quotes-table {
	width: 100%;
	border-collapse: collapse;
}
.quotes-table th,
.quotes-table td {
	padding: 12px;
	text-align: left;
	border-bottom: 1px solid var(--border-normal);
}
.quotes-table th {
	background: var(--background-normal);
	font-weight: 600;
	color: var(--foreground-subdued);
}
.quotes-table tr:hover {
	background: var(--background-normal);
}
.quote-num {
	font-weight: 600;
	color: var(--primary);
}
.action-btn {
	padding: 4px 12px;
	background: var(--background-normal);
	border: 1px solid var(--border-normal);
	border-radius: 4px;
	cursor: pointer;
	color: var(--foreground-normal);
}
.action-btn:hover {
	background: var(--primary);
	color: white;
}
.action-btn.download {
	margin-left: 4px;
}
.filters-section {
	background: var(--background-normal);
	padding: 16px;
	border-radius: 8px;
	margin-bottom: 16px;
}
.filter-row {
	display: flex;
	flex-wrap: wrap;
	gap: 16px;
	align-items: flex-end;
}
.filter-group {
	display: flex;
	flex-direction: column;
	gap: 4px;
}
.filter-group label {
	font-size: 12px;
	color: var(--foreground-subdued);
	font-weight: 500;
}
.filter-input {
	padding: 8px 12px;
	border: 1px solid var(--border-normal);
	border-radius: 4px;
	background: var(--background-page);
	color: var(--foreground-normal);
	min-width: 150px;
}
.filter-input:focus {
	outline: none;
	border-color: var(--primary);
}
.filter-actions {
	display: flex;
	gap: 8px;
}
.btn-primary {
	padding: 8px 16px;
	background: var(--primary);
	color: white;
	border: none;
	border-radius: 4px;
	cursor: pointer;
	font-weight: 500;
}
.btn-primary:hover {
	opacity: 0.9;
}
.btn-secondary {
	padding: 8px 16px;
	background: var(--background-normal-alt);
	color: var(--foreground-normal);
	border: 1px solid var(--border-normal);
	border-radius: 4px;
	cursor: pointer;
}
.btn-secondary:hover {
	background: var(--background-normal);
}
.btn-download {
	padding: 8px 16px;
	background: #10b981;
	color: white;
	border: none;
	border-radius: 4px;
	cursor: pointer;
	font-weight: 500;
}
.btn-download:hover {
	background: #059669;
}
.results-info {
	padding: 8px 12px;
	background: var(--background-normal);
	border-radius: 4px;
	margin-bottom: 12px;
	font-size: 13px;
	color: var(--foreground-subdued);
}
</style>
