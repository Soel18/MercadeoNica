<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mercadeonica.modelo.Vendedor" %>
<%
    Vendedor vendedor = (Vendedor) session.getAttribute("vendedor");
    if (vendedor == null || !vendedor.esAdmin()) {
        response.sendRedirect("menu.jsp");
        return;
    }

    Double totalFacturado = (Double) request.getAttribute("totalFacturado");
    Double totalFacturadoAnterior = (Double) request.getAttribute("totalFacturadoAnterior");
    Double ticketPromedio = (Double) request.getAttribute("ticketPromedio");
    Integer totalClientes = (Integer) request.getAttribute("totalClientes");
    Integer pedidosPendientes = (Integer) request.getAttribute("pedidosPendientes");
    Integer productosBajoStock = (Integer) request.getAttribute("productosBajoStock");
    String filtroFecha = (String) request.getAttribute("filtroFecha");
    String fechaInicio = (String) request.getAttribute("fechaInicio");
    String fechaFin = (String) request.getAttribute("fechaFin");

    double variacion = 0;
    if (totalFacturadoAnterior != null && totalFacturadoAnterior > 0) {
        variacion = ((totalFacturado - totalFacturadoAnterior) / totalFacturadoAnterior) * 100;
    }
    boolean subio = variacion >= 0;
    String colorVariacion = subio ? "#27ae60" : "#c0392b";
    String iconoVariacion = subio ? "↑" : "↓";

    List<Object[]> ventasPorMes = (List<Object[]>) request.getAttribute("ventasPorMes");
    List<Object[]> ventasPeriodoAnterior = (List<Object[]>) request.getAttribute("ventasPeriodoAnterior");
    List<Object[]> pedidosPorEstado = (List<Object[]>) request.getAttribute("pedidosPorEstado");
    List<Object[]> topProductos = (List<Object[]>) request.getAttribute("topProductos");
    List<Object[]> topClientes = (List<Object[]>) request.getAttribute("topClientes");
    List<Object[]> ventasVendedor = (List<Object[]>) request.getAttribute("ventasVendedor");
    List<Object[]> clientesPorCategoria = (List<Object[]>) request.getAttribute("clientesPorCategoria");
    List<Object[]> listaBajoStock = (List<Object[]>) request.getAttribute("listaBajoStock");
    
    List<Object[]> ventasPorHora = (List<Object[]>) request.getAttribute("ventasPorHora");
    List<Object[]> ventasPorCategoriaProd = (List<Object[]>) request.getAttribute("ventasPorCategoriaProd");
    List<Object[]> metodosPago = (List<Object[]>) request.getAttribute("metodosPago");
    List<Object[]> topProductosCalificados = (List<Object[]>) request.getAttribute("topProductosCalificados");

    Integer limiteBajoStock = (Integer) request.getAttribute("limiteBajoStock");
    if (limiteBajoStock == null) limiteBajoStock = 50;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Dashboard Ejecutivo - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels"></script>
    <style>
        .kpi-card { background: white; border-radius: 10px; padding: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); text-align: center; transition: transform 0.2s; }
        .kpi-card:hover { transform: translateY(-5px); }
        .kpi-title { font-size: 0.9em; color: #7f8c8d; font-weight: 600; text-transform: uppercase; letter-spacing: 1px; }
        .kpi-value { font-size: 2.2em; font-weight: bold; margin-top: 10px; }
        .filtro-btn { padding: 10px 20px; border-radius: 5px; text-decoration: none; font-weight: bold; transition: 0.2s; }
        .filtro-activo { background-color: #2c3e50; color: white; }
        .filtro-inactivo { background-color: #ecf0f1; color: #2c3e50; }
        .filtro-inactivo:hover { background-color: #bdc3c7; }
        
        .chart-container { position: relative; height: 380px; width: 100%; }
        
        .grid-2 { display: grid; grid-template-columns: repeat(2, 1fr); gap: 25px; margin-bottom: 25px; }
        .grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 25px; margin-bottom: 25px; }

        /* 🔥 ESTILOS DE IMPRESIÓN OPTIMIZADOS */
        @media print {
            body { background: white; padding: 0; }
            header, nav, .user-info, .filtro-btn, .btn-imprimir, .filtro-personalizado, .kpi-card, .no-print { display: none !important; }
            main { max-width: 100% !important; padding: 0 !important; margin: 0 !important; }
            
            /* Evitar cortes y dar espacio */
            .module-card { 
                box-shadow: none !important; 
                border: 1px solid #ddd !important; 
                page-break-inside: avoid; 
                margin-bottom: 30px !important; 
                padding: 15px !important;
            }
            .module-card h3 {
                margin-bottom: 15px !important;
                margin-top: 0 !important;
            }
            
            /* Vertical: 1 por fila */
            .grid-2, .grid-3 { 
                grid-template-columns: 1fr !important; 
                gap: 30px !important; 
            }
            .chart-container { height: 350px !important; }
        }
        
        /* 🔥 HORIZONTAL: 2 por fila, ocupan todo el ancho, salto de página cada 2 */
        @media print and (orientation: landscape) {
            .grid-2, .grid-3 { 
                grid-template-columns: repeat(2, 1fr) !important; 
                gap: 20px !important;
                page-break-after: always; /* Salto de hoja después de cada par */
            }
            /* El último par no necesita salto para no dejar hoja vacía */
            .grid-2:last-child, .grid-3:last-child {
                page-break-after: auto;
            }
            .chart-container { height: 350px !important; } /* Más altura para que se vean grandes */
            .module-card { padding: 15px !important; margin-bottom: 10px !important; }
            .module-card h3 { font-size: 1.1em !important; margin-bottom: 10px !important; }
        }
    </style>
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <a href="menu.jsp">Inicio</a>
            <a href="ProductoServlet">Productos</a>
            <a href="ClienteServlet">Clientes</a>
            <a href="carrito.jsp">Carrito</a>
            <a href="PedidoServlet">Pedidos</a>
            <a href="DashboardServlet"><b>Dashboard</b></a>
            <a href="ReporteServlet">Reportes</a>
            <a href="VendedorServlet">Vendedores</a>
        </nav>
        <div class="user-info">
            <span>👤 <%= vendedor.getNombre() %></span>
            <span class="badge" style="background-color: #e74c3c;"><%= vendedor.getRol() %></span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main style="max-width: 1600px;">
        <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
            <h2 style="margin-bottom: 0;">📊 Panel de Control Ejecutivo</h2>
            
            <button onclick="window.print()" class="btn-imprimir btn-primary" style="background-color: #8e44ad; cursor: pointer;">
                🖨️ Imprimir / PDF
            </button>
        </div>

        <!-- FILTROS DE FECHA -->
        <div style="display: flex; gap: 10px; margin: 20px 0; flex-wrap: wrap; align-items: center;">
            <a href="DashboardServlet?filtroFecha=todos" class="filtro-btn <%= "todos".equals(filtroFecha) ? "filtro-activo" : "filtro-inactivo" %>">📊 Todos</a>
            <a href="DashboardServlet?filtroFecha=mes_actual" class="filtro-btn <%= "mes_actual".equals(filtroFecha) ? "filtro-activo" : "filtro-inactivo" %>">📅 Este Mes</a>
            <a href="DashboardServlet?filtroFecha=ultimos_3_meses" class="filtro-btn <%= "ultimos_3_meses".equals(filtroFecha) ? "filtro-activo" : "filtro-inactivo" %>">📅 Últimos 3 Meses</a>
            <a href="DashboardServlet?filtroFecha=este_anio" class="filtro-btn <%= "este_anio".equals(filtroFecha) ? "filtro-activo" : "filtro-inactivo" %>">📅 Este Año</a>
            
            <form action="DashboardServlet" method="get" class="filtro-personalizado" style="display: flex; gap: 5px; align-items: center; background: #f8f9fa; padding: 5px 10px; border-radius: 5px; border: 1px solid #ddd;">
                <input type="hidden" name="filtroFecha" value="personalizado">
                <input type="date" name="fechaInicio" value="<%= fechaInicio != null ? fechaInicio : "" %>" required style="padding: 5px; border: 1px solid #ccc; border-radius: 4px;">
                <span>a</span>
                <input type="date" name="fechaFin" value="<%= fechaFin != null ? fechaFin : "" %>" required style="padding: 5px; border: 1px solid #ccc; border-radius: 4px;">
                <button type="submit" class="btn-primary" style="padding: 6px 12px; background-color: #2c3e50;">Filtrar</button>
            </form>
        </div>

        <!-- FILA 1: TARJETAS KPI -->
        <div style="display: grid; grid-template-columns: repeat(5, 1fr); gap: 20px; margin-bottom: 30px;">
            <div class="kpi-card" style="border-top: 4px solid #27ae60;">
                <div class="kpi-title">💰 Total Facturado</div>
                <div class="kpi-value" style="color: #27ae60;">$<%= String.format("%,.2f", totalFacturado != null ? totalFacturado : 0) %></div>
                <div style="font-size: 0.9em; color: <%= colorVariacion %>; font-weight: bold; margin-top: 5px;">
                    <%= iconoVariacion %> <%= String.format("%.1f", Math.abs(variacion)) %>% vs anterior
                </div>
            </div>
            <div class="kpi-card" style="border-top: 4px solid #8e44ad;">
                <div class="kpi-title">💳 Ticket Promedio</div>
                <div class="kpi-value" style="color: #8e44ad;">$<%= String.format("%,.2f", ticketPromedio != null ? ticketPromedio : 0) %></div>
            </div>
            <div class="kpi-card" style="border-top: 4px solid #2980b9;">
                <div class="kpi-title">👥 Clientes Activos</div>
                <div class="kpi-value" style="color: #2980b9;"><%= totalClientes != null ? totalClientes : 0 %></div>
            </div>
            <div class="kpi-card" style="border-top: 4px solid #f39c12;">
                <div class="kpi-title">⏳ Pendientes</div>
                <div class="kpi-value" style="color: #f39c12;"><%= pedidosPendientes != null ? pedidosPendientes : 0 %></div>
            </div>
            <div class="kpi-card" style="border-top: 4px solid #c0392b;">
                <div class="kpi-title">⚠️ Bajo Stock</div>
                <div class="kpi-value" style="color: #c0392b;"><%= productosBajoStock != null ? productosBajoStock : 0 %></div>
            </div>
        </div>

        <!-- BLOQUE 1: 2 GRÁFICOS -->
        <div class="grid-2">
            <div class="module-card">
                <h3>📈 Evolución de Ventas (Actual vs Anterior)</h3>
                <div class="chart-container"><canvas id="graficoVentas"></canvas></div>
            </div>
            <div class="module-card">
                <h3>📌 Pedidos por Estado</h3>
                <div class="chart-container"><canvas id="graficoEstados"></canvas></div>
            </div>
        </div>

        <!-- BLOQUE 2: 2 GRÁFICOS -->
        <div class="grid-2">
            <div class="module-card">
                <h3>🕒 Ventas por Hora del Día</h3>
                <div class="chart-container"><canvas id="graficoHoras"></canvas></div>
            </div>
            <div class="module-card">
                <h3>🏷️ Ventas por Categoría de Producto</h3>
                <div class="chart-container"><canvas id="graficoCatProducto"></canvas></div>
            </div>
        </div>

        <!-- BLOQUE 3: 2 GRÁFICOS (Aunque sean 3 en el código, ponemos 2 en la primera fila) -->
        <div class="grid-2">
            <div class="module-card">
                <h3>💳 Métodos de Pago</h3>
                <div class="chart-container"><canvas id="graficoPagos"></canvas></div>
            </div>
            <div class="module-card">
                <h3>🏆 Top 5 Mejores Clientes ($)</h3>
                <div class="chart-container"><canvas id="graficoTopClientes"></canvas></div>
            </div>
        </div>

        <!-- BLOQUE 4: 2 GRÁFICOS -->
        <div class="grid-2">
            <div class="module-card">
                <h3>🏆 Top Vendedores por Ventas ($)</h3>
                <div class="chart-container"><canvas id="graficoVentasVendedor"></canvas></div>
            </div>
            <div class="module-card">
                <h3>👥 Clientes por Categoría</h3>
                <div class="chart-container"><canvas id="graficoCatClientes"></canvas></div>
            </div>
        </div>

        <!-- BLOQUE 5: 2 GRÁFICOS -->
        <div class="grid-2">
            <div class="module-card">
                <h3>📦 Top 5 Más Vendidos</h3>
                <div class="chart-container"><canvas id="graficoTopProductos"></canvas></div>
            </div>
            <div class="module-card">
                <h3>⭐ Top 5 Mejor Calificados</h3>
                <div class="chart-container"><canvas id="graficoTopCalificados"></canvas></div>
            </div>
        </div>

        <!-- BLOQUE 6: ALERTA INVENTARIO -->
        <div class="grid-2">
            <div class="module-card">
                <h3>🚨 Alertas de Inventario (&lt; <%= limiteBajoStock %> un.)</h3>
                <table style="width: 100%; font-size: 0.95em; margin-top: 10px;">
                    <thead><tr><th>Producto</th><th>Stock</th></tr></thead>
                    <tbody>
                        <% if (listaBajoStock != null && !listaBajoStock.isEmpty()) {
                            for (Object[] p : listaBajoStock) { 
                                int stock = (Integer) p[1];
                                String colorStock = stock <= 10 ? "#c0392b" : (stock <= 30 ? "#e67e22" : "#f39c12");
                                String icono = stock <= 10 ? "⚠️" : "📉";
                        %>
                            <tr>
                                <td><%= p[0] %></td>
                                <td><span style="color: <%= colorStock %>; font-weight: bold; white-space: nowrap;"><%= icono %> <%= stock %> un.</span></td>
                            </tr>
                        <% }} else { %>
                            <tr><td colspan="2" style="text-align:center; color:#27ae60;">✅ Todo al día</td></tr>
                        <% } %>
                    </tbody>
                </table>
                <a href="ProductoServlet" class="btn" style="margin-top: 15px; width: 100%; text-align: center; background-color: #c0392b;">Gestionar Inventario</a>
            </div>
            <div></div>
        </div>
    </main>

    <script>
        Chart.register(ChartDataLabels);

        // 1. Ventas Comparativas
        const labelsVentas = [<% if (ventasPorMes != null) for (int i = 0; i < ventasPorMes.size(); i++) { %>'<%= ventasPorMes.get(i)[0] %>'<%= (i < ventasPorMes.size() - 1) ? "," : "" %><% } %>];
        const dataVentas = [<% if (ventasPorMes != null) for (int i = 0; i < ventasPorMes.size(); i++) { %><%= ventasPorMes.get(i)[1] %><%= (i < ventasPorMes.size() - 1) ? "," : "" %><% } %>];
        const dataVentasAnterior = [<% if (ventasPeriodoAnterior != null) for (int i = 0; i < ventasPeriodoAnterior.size(); i++) { %><%= ventasPeriodoAnterior.get(i)[1] %><%= (i < ventasPeriodoAnterior.size() - 1) ? "," : "" %><% } %>];

        new Chart(document.getElementById('graficoVentas').getContext('2d'), {
            type: 'line',
            data: {
                labels: labelsVentas,
                datasets: [
                    { label: 'Periodo Actual', data: dataVentas, borderColor: '#27ae60', backgroundColor: 'rgba(39, 174, 96, 0.2)', fill: true, tension: 0.4 },
                    { label: 'Periodo Anterior', data: dataVentasAnterior, borderColor: '#95a5a6', borderDash: [5, 5], fill: false, tension: 0.4 }
                ]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'top' }, datalabels: { display: false } } }
        });

        // 2. Pedidos por Estado
        const labelsEstados = [<% if (pedidosPorEstado != null) for (int i = 0; i < pedidosPorEstado.size(); i++) { %>'<%= pedidosPorEstado.get(i)[0] %>'<%= (i < pedidosPorEstado.size() - 1) ? "," : "" %><% } %>];
        const dataEstados = [<% if (pedidosPorEstado != null) for (int i = 0; i < pedidosPorEstado.size(); i++) { %><%= pedidosPorEstado.get(i)[1] %><%= (i < pedidosPorEstado.size() - 1) ? "," : "" %><% } %>];
        const coloresEstados = labelsEstados.map(label => {
            const nombre = label.toUpperCase().trim();
            if (nombre === 'PENDIENTE') return '#f39c12';
            if (nombre === 'CONFIRMADO') return '#3498db';
            if (nombre === 'ENTREGADO') return '#27ae60';
            if (nombre === 'CANCELADO') return '#c0392b';
            return '#95a5a6';
        });
        new Chart(document.getElementById('graficoEstados').getContext('2d'), {
            type: 'doughnut',
            data: { labels: labelsEstados, datasets: [{ data: dataEstados, backgroundColor: coloresEstados }] },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' }, datalabels: { color: 'white', font: { weight: 'bold', size: 14 } } } }
        });

        // 3. Ventas por Hora
        new Chart(document.getElementById('graficoHoras').getContext('2d'), {
            type: 'bar',
            data: {
                labels: [<% if (ventasPorHora != null) for (int i = 0; i < ventasPorHora.size(); i++) { %>'<%= ventasPorHora.get(i)[0] %>'<%= (i < ventasPorHora.size() - 1) ? "," : "" %><% } %>],
                datasets: [{ label: 'Ventas ($)', data: [<% if (ventasPorHora != null) for (int i = 0; i < ventasPorHora.size(); i++) { %><%= ventasPorHora.get(i)[1] %><%= (i < ventasPorHora.size() - 1) ? "," : "" %><% } %>], backgroundColor: '#2980b9' }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, datalabels: { color: '#2980b9', anchor: 'end', align: 'end', font: { weight: 'bold', size: 11 }, formatter: (val) => '$' + val.toLocaleString() } } }
        });

        // 4. Ventas por Categoría de Producto
        new Chart(document.getElementById('graficoCatProducto').getContext('2d'), {
            type: 'bar',
            data: {
                labels: [<% if (ventasPorCategoriaProd != null) for (int i = 0; i < ventasPorCategoriaProd.size(); i++) { %>'<%= ventasPorCategoriaProd.get(i)[0] %>'<%= (i < ventasPorCategoriaProd.size() - 1) ? "," : "" %><% } %>],
                datasets: [{ 
                    label: 'Ventas ($)', 
                    data: [<% if (ventasPorCategoriaProd != null) for (int i = 0; i < ventasPorCategoriaProd.size(); i++) { %><%= ventasPorCategoriaProd.get(i)[1] %><%= (i < ventasPorCategoriaProd.size() - 1) ? "," : "" %><% } %>], 
                    backgroundColor: '#1abc9c' 
                }]
            },
            options: { 
                indexAxis: 'y', 
                responsive: true, 
                maintainAspectRatio: false, 
                layout: { padding: { right: 70 } },
                plugins: { 
                    legend: { display: false }, 
                    datalabels: { 
                        color: '#16a085', 
                        anchor: 'end', 
                        align: 'right', 
                        offset: 6, 
                        font: { weight: 'bold', size: 11 }, 
                        formatter: (value) => '$' + value.toLocaleString() 
                    } 
                } 
            }
        });

        // 5. Métodos de Pago
        new Chart(document.getElementById('graficoPagos').getContext('2d'), {
            type: 'pie',
            data: {
                labels: [<% if (metodosPago != null) for (int i = 0; i < metodosPago.size(); i++) { %>'<%= metodosPago.get(i)[0] %>'<%= (i < metodosPago.size() - 1) ? "," : "" %><% } %>],
                datasets: [{ data: [<% if (metodosPago != null) for (int i = 0; i < metodosPago.size(); i++) { %><%= metodosPago.get(i)[1] %><%= (i < metodosPago.size() - 1) ? "," : "" %><% } %>], backgroundColor: ['#3498db', '#e74c3c', '#f39c12', '#9b59b6', '#1abc9c'] }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' }, datalabels: { color: 'white', font: { weight: 'bold', size: 12 } } } }
        });

        // 6. Top Clientes
        new Chart(document.getElementById('graficoTopClientes').getContext('2d'), {
            type: 'bar',
            data: {
                labels: [<% if (topClientes != null) for (int i = 0; i < topClientes.size(); i++) { %>'<%= topClientes.get(i)[0] %>'<%= (i < topClientes.size() - 1) ? "," : "" %><% } %>],
                datasets: [{ label: 'Gastado ($)', data: [<% if (topClientes != null) for (int i = 0; i < topClientes.size(); i++) { %><%= topClientes.get(i)[1] %><%= (i < topClientes.size() - 1) ? "," : "" %><% } %>], backgroundColor: '#8e44ad' }]
            },
            options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, layout: { padding: { right: 60 } }, plugins: { legend: { display: false }, datalabels: { color: '#6c3483', anchor: 'end', align: 'right', offset: 6, font: { weight: 'bold', size: 11 }, formatter: (value) => '$' + value.toLocaleString() } } }
        });

        // 7. Clientes por Categoría
        const labelsCatClientes = [<% if (clientesPorCategoria != null) for (int i = 0; i < clientesPorCategoria.size(); i++) { %>'<%= clientesPorCategoria.get(i)[0] %>'<%= (i < clientesPorCategoria.size() - 1) ? "," : "" %><% } %>];
        const coloresCatClientes = labelsCatClientes.map(label => {
            const nombre = label.toUpperCase().trim();
            if (nombre === 'REGULAR')  return '#7f8c8d'; // Gris
            if (nombre === 'BRONCE')   return '#cd7f32'; // Bronce
            if (nombre === 'PLATA')    return '#bdc3c7'; // Plata claro (más visible que #95a5a6)
            if (nombre === 'ORO')      return '#f1c40f'; // Oro brillante
            if (nombre === 'PLATINO')  return '#8e44ad'; // Morado platino
            if (nombre === 'SIN CATEGORIA' || nombre === 'SIN CATEGORÍA') return '#e74c3c'; // Rojo para las que no tienen categoría
            return '#95a5a6'; // Color por defecto
        });
        new Chart(document.getElementById('graficoCatClientes').getContext('2d'), {
            type: 'doughnut',
            data: { labels: labelsCatClientes, datasets: [{ data: [<% if (clientesPorCategoria != null) for (int i = 0; i < clientesPorCategoria.size(); i++) { %><%= clientesPorCategoria.get(i)[1] %><%= (i < clientesPorCategoria.size() - 1) ? "," : "" %><% } %>], backgroundColor: coloresCatClientes }] },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' }, datalabels: { color: 'white', font: { weight: 'bold', size: 12 } } } }
        });

        // 8. Top Vendedores
        new Chart(document.getElementById('graficoVentasVendedor').getContext('2d'), {
            type: 'bar',
            data: {
                labels: [<% if (ventasVendedor != null) for (int i = 0; i < ventasVendedor.size(); i++) { %>'<%= ventasVendedor.get(i)[0] %>'<%= (i < ventasVendedor.size() - 1) ? "," : "" %><% } %>],
                datasets: [{ label: 'Ventas ($)', data: [<% if (ventasVendedor != null) for (int i = 0; i < ventasVendedor.size(); i++) { %><%= ventasVendedor.get(i)[1] %><%= (i < ventasVendedor.size() - 1) ? "," : "" %><% } %>], backgroundColor: '#e67e22' }]
            },
            options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, layout: { padding: { right: 60 } }, plugins: { legend: { display: false }, datalabels: { color: '#b9770e', anchor: 'end', align: 'right', offset: 6, font: { weight: 'bold', size: 11 }, formatter: (value) => '$' + value.toLocaleString() } } }
        });

        // 9. Top Productos Más Vendidos
        new Chart(document.getElementById('graficoTopProductos').getContext('2d'), {
            type: 'bar',
            data: {
                labels: [<% if (topProductos != null) for (int i = 0; i < topProductos.size(); i++) { %>'<%= topProductos.get(i)[0] %>'<%= (i < topProductos.size() - 1) ? "," : "" %><% } %>],
                datasets: [{ label: 'Unidades', data: [<% if (topProductos != null) for (int i = 0; i < topProductos.size(); i++) { %><%= topProductos.get(i)[1] %><%= (i < topProductos.size() - 1) ? "," : "" %><% } %>], backgroundColor: '#3498db' }]
            },
            options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, layout: { padding: { right: 40 } }, plugins: { legend: { display: false }, datalabels: { color: '#2980b9', anchor: 'end', align: 'right', offset: 6, font: { weight: 'bold', size: 12 } } } }
        });

        // 10. Top Productos Mejor Calificados
        new Chart(document.getElementById('graficoTopCalificados').getContext('2d'), {
            type: 'bar',
            data: {
                labels: [<% if (topProductosCalificados != null) for (int i = 0; i < topProductosCalificados.size(); i++) { %>'<%= topProductosCalificados.get(i)[0] %>'<%= (i < topProductosCalificados.size() - 1) ? "," : "" %><% } %>],
                datasets: [{ label: 'Estrellas', data: [<% if (topProductosCalificados != null) for (int i = 0; i < topProductosCalificados.size(); i++) { %><%= topProductosCalificados.get(i)[1] %><%= (i < topProductosCalificados.size() - 1) ? "," : "" %><% } %>], backgroundColor: '#f1c40f' }]
            },
            options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, layout: { padding: { right: 40 } }, plugins: { legend: { display: false }, datalabels: { color: '#d4ac0d', anchor: 'end', align: 'right', offset: 6, font: { weight: 'bold', size: 12 }, formatter: (val) => val.toFixed(1) + ' ⭐' } } }
        });
    </script>
</body>
</html>