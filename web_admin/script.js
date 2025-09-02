// Configuration Supabase
const SUPABASE_URL = 'https://kdgwsqlpvqwzzrjgwtel.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkZ3dzcWxwdnF3enpyamd3dGVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwNjY4MzcsImV4cCI6MjA3MDY0MjgzN30.RoNUk9AlX1PFkR7u_jbbjz0CNUsKNlJlAbHqTviXpQ4';

// Initialisation de Supabase
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Variables globales
let currentSection = 'dashboard';
let charts = {};

// Initialisation de l'application
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    setupEventListeners();
    loadDashboardData();
});

// Initialisation de l'application
function initializeApp() {
    console.log('Admin Panel Aya Huile initialisé');
    
    // Vérifier l'authentification
    checkAuth();
    
    // Initialiser les graphiques
    initializeCharts();
}

// Configuration des événements
function setupEventListeners() {
    // Navigation
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const section = this.getAttribute('href').substring(1);
            showSection(section);
        });
    });

    // Formulaire de génération de QR codes
    document.getElementById('qrGenerationForm').addEventListener('submit', function(e) {
        e.preventDefault();
        generateQRCodes();
    });

    // Formulaire de rapports
    document.getElementById('reportForm').addEventListener('submit', function(e) {
        e.preventDefault();
        generateReport();
    });
}

// Vérifier l'authentification
async function checkAuth() {
    try {
        const { data: { user }, error } = await supabase.auth.getUser();
        
        if (error || !user) {
            showNotification('Veuillez vous connecter pour accéder au panel admin', 'warning');
            // Rediriger vers la page de connexion si nécessaire
        }
    } catch (error) {
        console.error('Erreur d\'authentification:', error);
    }
}

// Afficher une section
function showSection(sectionName) {
    // Masquer toutes les sections
    document.querySelectorAll('.section').forEach(section => {
        section.style.display = 'none';
    });

    // Afficher la section demandée
    const targetSection = document.getElementById(sectionName);
    if (targetSection) {
        targetSection.style.display = 'block';
        currentSection = sectionName;
        
        // Charger les données spécifiques à la section
        switch (sectionName) {
            case 'dashboard':
                loadDashboardData();
                break;
            case 'qr-codes':
                loadQRCodesData();
                break;
            case 'users':
                loadUsersData();
                break;
            case 'exchanges':
                loadExchangesData();
                break;
            case 'reports':
                loadReportsData();
                break;
        }
    }
}

// Charger les données du dashboard
async function loadDashboardData() {
    try {
        showLoading('Chargement des statistiques...');
        
        // Charger les statistiques globales
        const stats = await getGlobalStats();
        updateDashboardStats(stats);
        
        // Charger les graphiques
        updateCharts(stats);
        
        hideLoading();
    } catch (error) {
        console.error('Erreur lors du chargement du dashboard:', error);
        showNotification('Erreur lors du chargement des données', 'danger');
        hideLoading();
    }
}

// Obtenir les statistiques globales
async function getGlobalStats() {
    try {
        // Statistiques des utilisateurs
        const { data: users, error: usersError } = await supabase
            .from('users')
            .select('*');
        
        if (usersError) throw usersError;

        // Statistiques des QR codes
        const { data: qrCodes, error: qrError } = await supabase
            .from('qr_codes')
            .select('*');
        
        if (qrError) throw qrError;

        // Statistiques des jeux
        const { data: games, error: gamesError } = await supabase
            .from('game_history')
            .select('*');
        
        if (gamesError) throw gamesError;

        // Statistiques des échanges
        const { data: exchanges, error: exchangesError } = await supabase
            .from('exchange_requests')
            .select('*');
        
        if (exchangesError) throw exchangesError;

        return {
            users: users || [],
            qrCodes: qrCodes || [],
            games: games || [],
            exchanges: exchanges || []
        };
    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques:', error);
        throw error;
    }
}

// Mettre à jour les statistiques du dashboard
function updateDashboardStats(stats) {
    // Utilisateurs
    document.getElementById('totalUsers').textContent = stats.users.length;
    
    // QR codes scannés
    const scannedQRCodes = stats.qrCodes.filter(qr => qr.is_used).length;
    document.getElementById('totalScans').textContent = scannedQRCodes;
    
    // Jeux joués
    document.getElementById('totalGames').textContent = stats.games.length;
    
    // Échanges
    document.getElementById('totalExchanges').textContent = stats.exchanges.length;
}

// Initialiser les graphiques
function initializeCharts() {
    // Graphique de répartition des QR codes
    const qrCodesCtx = document.getElementById('qrCodesChart').getContext('2d');
    charts.qrCodes = new Chart(qrCodesCtx, {
        type: 'doughnut',
        data: {
            labels: ['10 points', '50 points', '100 points', 'Réessayer', 'Fidélité'],
            datasets: [{
                data: [0, 0, 0, 0, 0],
                backgroundColor: [
                    '#28a745',
                    '#17a2b8',
                    '#ffc107',
                    '#dc3545',
                    '#6f42c1'
                ]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom'
                }
            }
        }
    });

    // Graphique d'activité récente
    const activityCtx = document.getElementById('activityChart').getContext('2d');
    charts.activity = new Chart(activityCtx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Activité quotidienne',
                data: [],
                borderColor: '#28a745',
                backgroundColor: 'rgba(40, 167, 69, 0.1)',
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });
}

// Mettre à jour les graphiques
function updateCharts(stats) {
    // Répartition des QR codes
    const qrDistribution = {
        10: 0, 50: 0, 100: 0, 0: 0, 25: 0
    };
    
    stats.qrCodes.forEach(qr => {
        qrDistribution[qr.points] = (qrDistribution[qr.points] || 0) + 1;
    });
    
    charts.qrCodes.data.datasets[0].data = [
        qrDistribution[10],
        qrDistribution[50],
        qrDistribution[100],
        qrDistribution[0],
        qrDistribution[25]
    ];
    charts.qrCodes.update();

    // Activité récente (7 derniers jours)
    const activityData = getActivityData(stats);
    charts.activity.data.labels = activityData.labels;
    charts.activity.data.datasets[0].data = activityData.data;
    charts.activity.update();
}

// Obtenir les données d'activité
function getActivityData(stats) {
    const labels = [];
    const data = [];
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
        const date = new Date(today);
        date.setDate(date.getDate() - i);
        const dateStr = date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' });
        labels.push(dateStr);
        
        // Compter les activités pour cette date
        const dayStart = new Date(date);
        dayStart.setHours(0, 0, 0, 0);
        const dayEnd = new Date(date);
        dayEnd.setHours(23, 59, 59, 999);
        
        const dayActivities = stats.games.filter(game => {
            const gameDate = new Date(game.played_at);
            return gameDate >= dayStart && gameDate <= dayEnd;
        }).length;
        
        data.push(dayActivities);
    }
    
    return { labels, data };
}

// Charger les données des QR codes
async function loadQRCodesData() {
    try {
        showLoading('Chargement des QR codes...');
        
        const { data: qrCodes, error } = await supabase
            .from('qr_codes')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(100);
        
        if (error) throw error;
        
        updateQRCodesTable(qrCodes);
        updateQRStats(qrCodes);
        
        hideLoading();
    } catch (error) {
        console.error('Erreur lors du chargement des QR codes:', error);
        showNotification('Erreur lors du chargement des QR codes', 'danger');
        hideLoading();
    }
}

// Mettre à jour le tableau des QR codes
function updateQRCodesTable(qrCodes) {
    const tbody = document.querySelector('#qrCodesTable tbody');
    tbody.innerHTML = '';
    
    qrCodes.forEach(qr => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td><code>${qr.code}</code></td>
            <td>${qr.points} points</td>
            <td>
                <span class="badge ${qr.is_used ? 'badge-success' : 'badge-warning'}">
                    ${qr.is_used ? 'Utilisé' : 'Disponible'}
                </span>
            </td>
            <td>${new Date(qr.created_at).toLocaleDateString('fr-FR')}</td>
            <td>
                <button class="btn btn-sm btn-outline-primary" onclick="viewQRCode('${qr.code}')">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn btn-sm btn-outline-danger" onclick="deleteQRCode('${qr.id}')">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Mettre à jour les statistiques des QR codes
function updateQRStats(qrCodes) {
    const stats = {
        total: qrCodes.length,
        used: qrCodes.filter(qr => qr.is_used).length,
        available: qrCodes.filter(qr => !qr.is_used).length,
        byPoints: {}
    };
    
    qrCodes.forEach(qr => {
        stats.byPoints[qr.points] = (stats.byPoints[qr.points] || 0) + 1;
    });
    
    const statsHtml = `
        <div class="stats-grid">
            <div class="stat-item">
                <div class="stat-value">${stats.total}</div>
                <div class="stat-label">Total</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">${stats.used}</div>
                <div class="stat-label">Utilisés</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">${stats.available}</div>
                <div class="stat-label">Disponibles</div>
            </div>
        </div>
        <h6>Répartition par points:</h6>
        <ul class="list-unstyled">
            ${Object.entries(stats.byPoints).map(([points, count]) => 
                `<li>${points} points: ${count} QR codes</li>`
            ).join('')}
        </ul>
    `;
    
    document.getElementById('qrStats').innerHTML = statsHtml;
}

// Générer de nouveaux QR codes
async function generateQRCodes() {
    try {
        const count = parseInt(document.getElementById('qrCount').value);
        const points = parseInt(document.getElementById('qrPoints').value);
        
        if (count <= 0 || count > 10000) {
            showNotification('Le nombre de QR codes doit être entre 1 et 10000', 'warning');
            return;
        }
        
        showLoading('Génération des QR codes...');
        
        // Appeler la fonction Supabase pour générer les QR codes
        const { data, error } = await supabase.rpc('generate_qr_codes', {
            qr_count: count,
            qr_points: points
        });
        
        if (error) throw error;
        
        showNotification(`${count} QR codes générés avec succès!`, 'success');
        
        // Recharger les données
        loadQRCodesData();
        
        hideLoading();
    } catch (error) {
        console.error('Erreur lors de la génération des QR codes:', error);
        showNotification('Erreur lors de la génération des QR codes', 'danger');
        hideLoading();
    }
}

// Charger les données des utilisateurs
async function loadUsersData() {
    try {
        showLoading('Chargement des utilisateurs...');
        
        const { data: users, error } = await supabase
            .from('users')
            .select('*')
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        
        updateUsersTable(users);
        
        hideLoading();
    } catch (error) {
        console.error('Erreur lors du chargement des utilisateurs:', error);
        showNotification('Erreur lors du chargement des utilisateurs', 'danger');
        hideLoading();
    }
}

// Mettre à jour le tableau des utilisateurs
function updateUsersTable(users) {
    const tbody = document.querySelector('#usersTable tbody');
    tbody.innerHTML = '';
    
    users.forEach(user => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${user.first_name} ${user.last_name}</td>
            <td>${user.email}</td>
            <td>${user.available_points} points</td>
            <td>${user.collected_qr_codes || 0}</td>
            <td>${new Date(user.created_at).toLocaleDateString('fr-FR')}</td>
            <td>
                <button class="btn btn-sm btn-outline-primary" onclick="viewUser('${user.id}')">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn btn-sm btn-outline-warning" onclick="editUser('${user.id}')">
                    <i class="fas fa-edit"></i>
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Charger les données des échanges
async function loadExchangesData() {
    try {
        showLoading('Chargement des échanges...');
        
        const { data: exchanges, error } = await supabase
            .from('exchange_requests')
            .select(`
                *,
                users(first_name, last_name, email)
            `)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        
        updateExchangesTable(exchanges);
        
        hideLoading();
    } catch (error) {
        console.error('Erreur lors du chargement des échanges:', error);
        showNotification('Erreur lors du chargement des échanges', 'danger');
        hideLoading();
    }
}

// Mettre à jour le tableau des échanges
function updateExchangesTable(exchanges) {
    const tbody = document.querySelector('#exchangesTable tbody');
    tbody.innerHTML = '';
    
    exchanges.forEach(exchange => {
        const user = exchange.users;
        const row = document.createElement('tr');
        row.innerHTML = `
            <td><code>${exchange.exchange_code}</code></td>
            <td>${user ? `${user.first_name} ${user.last_name}` : 'N/A'}</td>
            <td>${exchange.points_to_exchange} points</td>
            <td>
                <span class="badge badge-${getStatusBadgeClass(exchange.status)}">
                    ${getStatusLabel(exchange.status)}
                </span>
            </td>
            <td>${new Date(exchange.created_at).toLocaleDateString('fr-FR')}</td>
            <td>
                <button class="btn btn-sm btn-outline-success" onclick="approveExchange('${exchange.id}')" ${exchange.status !== 'pending' ? 'disabled' : ''}>
                    <i class="fas fa-check"></i>
                </button>
                <button class="btn btn-sm btn-outline-danger" onclick="rejectExchange('${exchange.id}')" ${exchange.status !== 'pending' ? 'disabled' : ''}>
                    <i class="fas fa-times"></i>
                </button>
                <button class="btn btn-sm btn-outline-info" onclick="viewExchange('${exchange.id}')">
                    <i class="fas fa-eye"></i>
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Obtenir la classe CSS du badge selon le statut
function getStatusBadgeClass(status) {
    switch (status) {
        case 'pending': return 'warning';
        case 'approved': return 'success';
        case 'rejected': return 'danger';
        case 'completed': return 'info';
        default: return 'secondary';
    }
}

// Obtenir le libellé du statut
function getStatusLabel(status) {
    switch (status) {
        case 'pending': return 'En attente';
        case 'approved': return 'Approuvé';
        case 'rejected': return 'Rejeté';
        case 'completed': return 'Terminé';
        default: return 'Inconnu';
    }
}

// Approuver un échange
async function approveExchange(exchangeId) {
    try {
        const { error } = await supabase
            .from('exchange_requests')
            .update({ status: 'approved' })
            .eq('id', exchangeId);
        
        if (error) throw error;
        
        showNotification('Échange approuvé avec succès', 'success');
        loadExchangesData();
    } catch (error) {
        console.error('Erreur lors de l\'approbation:', error);
        showNotification('Erreur lors de l\'approbation', 'danger');
    }
}

// Rejeter un échange
async function rejectExchange(exchangeId) {
    try {
        const { error } = await supabase
            .from('exchange_requests')
            .update({ status: 'rejected' })
            .eq('id', exchangeId);
        
        if (error) throw error;
        
        showNotification('Échange rejeté', 'warning');
        loadExchangesData();
    } catch (error) {
        console.error('Erreur lors du rejet:', error);
        showNotification('Erreur lors du rejet', 'danger');
    }
}

// Charger les données des rapports
function loadReportsData() {
    // Cette fonction peut être utilisée pour charger des rapports prédéfinis
    console.log('Chargement des données de rapports');
}

// Générer un rapport
async function generateReport() {
    try {
        const reportType = document.getElementById('reportType').value;
        const period = parseInt(document.getElementById('reportPeriod').value);
        
        showLoading('Génération du rapport...');
        
        // Ici, vous pouvez implémenter la logique de génération de rapport
        // selon le type et la période demandés
        
        const reportData = await generateReportData(reportType, period);
        
        // Télécharger le rapport
        downloadReport(reportData, reportType);
        
        showNotification('Rapport généré avec succès', 'success');
        hideLoading();
    } catch (error) {
        console.error('Erreur lors de la génération du rapport:', error);
        showNotification('Erreur lors de la génération du rapport', 'danger');
        hideLoading();
    }
}

// Générer les données du rapport
async function generateReportData(type, period) {
    // Implémentation selon le type de rapport
    switch (type) {
        case 'users':
            return await generateUsersReport(period);
        case 'qr-codes':
            return await generateQRCodesReport(period);
        case 'games':
            return await generateGamesReport(period);
        case 'exchanges':
            return await generateExchangesReport(period);
        case 'global':
            return await generateGlobalReport(period);
        default:
            throw new Error('Type de rapport non reconnu');
    }
}

// Télécharger le rapport
function downloadReport(data, type) {
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `rapport_${type}_${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    window.URL.revokeObjectURL(url);
}

// Fonctions utilitaires
function showLoading(message) {
    // Afficher un indicateur de chargement
    console.log('Loading:', message);
}

function hideLoading() {
    // Masquer l'indicateur de chargement
    console.log('Loading finished');
}

function showNotification(message, type) {
    // Créer une notification Bootstrap
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show notification`;
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(alertDiv);
    
    // Supprimer automatiquement après 5 secondes
    setTimeout(() => {
        if (alertDiv.parentNode) {
            alertDiv.parentNode.removeChild(alertDiv);
        }
    }, 5000);
}

// Fonctions pour les actions spécifiques
function viewQRCode(code) {
    alert(`Affichage du QR code: ${code}`);
    // Implémenter l'affichage détaillé du QR code
}

function deleteQRCode(id) {
    if (confirm('Êtes-vous sûr de vouloir supprimer ce QR code ?')) {
        // Implémenter la suppression
        console.log('Suppression du QR code:', id);
    }
}

function viewUser(id) {
    alert(`Affichage de l'utilisateur: ${id}`);
    // Implémenter l'affichage détaillé de l'utilisateur
}

function editUser(id) {
    alert(`Édition de l'utilisateur: ${id}`);
    // Implémenter l'édition de l'utilisateur
}

function viewExchange(id) {
    alert(`Affichage de l'échange: ${id}`);
    // Implémenter l'affichage détaillé de l'échange
}

// Fonctions de génération de rapports (à implémenter selon vos besoins)
async function generateUsersReport(period) {
    // Implémenter le rapport utilisateurs
    return { type: 'users', period, data: [] };
}

async function generateQRCodesReport(period) {
    // Implémenter le rapport QR codes
    return { type: 'qr-codes', period, data: [] };
}

async function generateGamesReport(period) {
    // Implémenter le rapport jeux
    return { type: 'games', period, data: [] };
}

async function generateExchangesReport(period) {
    // Implémenter le rapport échanges
    return { type: 'exchanges', period, data: [] };
}

async function generateGlobalReport(period) {
    // Implémenter le rapport global
    return { type: 'global', period, data: [] };
}
