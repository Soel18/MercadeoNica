<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mercadeonica.modelo.Pedido" %>
<%@ page import="com.mercadeonica.modelo.Vendedor" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    Vendedor vendedor = (Vendedor) session.getAttribute("vendedor");
    if (vendedor == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Pedido> pedidos = (List<Pedido>) request.getAttribute("pedidos");
    String mensaje = (String) request.getAttribute("mensaje");
    String error = (String) request.getAttribute("error");
    String filtroActual = (String) request.getAttribute("filtroActual");
    boolean esAdmin = vendedor.esAdmin();

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Pedidos - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
                <nav>
            <a href="menu.jsp">Inicio</a>
            <% if (esAdmin) { %>
                <a href="DashboardServlet">Dashboard</a>
            <% } %>
            <a href="ProductoServlet">Productos</a>
            <a href="ClienteServlet">Clientes</a>
            <a href="carrito.jsp">Carrito</a>
            <a href="PedidoServlet"><b>Pedidos</b></a>
            <% if (esAdmin) { %>
                <a href="ReporteServlet">Reportes</a>
                <a href="VendedorServlet">Vendedores</a>
            <% } %>
        </nav>
        <div class="user-info">
            <span>👤 <%= vendedor.getNombre() %></span>
            <span class="badge" style="background-color: <%= esAdmin ? "#e74c3c" : "#3498db" %>;">
                <%= vendedor.getRol() %>
            </span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <% if (mensaje != null) { %>
            <div class="ok">✅ <%= mensaje %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="error">⚠️ <%= error %></div>
        <% } %>

        <h2>🧾 Historial de Pedidos</h2>

        <div style="margin: 20px 0; display: flex; gap: 10px; flex-wrap: wrap; align-items: center;">
            <span style="font-weight: bold;">Filtrar por estado:</span>
            <a href="PedidoServlet" class="btn"
               style="<%= filtroActual == null ? "background-color: #2c3e50;" : "background-color: #95a5a6;" %>">
               Todos
            </a>
            <a href="PedidoServlet?filtro=PENDIENTE" class="btn"
               style="<%= "PENDIENTE".equals(filtroActual) ? "background-color: #f39c12;" : "background-color: #95a5a6;" %>">
               🟠 Pendientes
            </a>
            <a href="PedidoServlet?filtro=CONFIRMADO" class="btn"
               style="<%= "CONFIRMADO".equals(filtroActual) ? "background-color: #3498db;" : "background-color: #95a5a6;" %>">
               🔵 Confirmados
            </a>
            <a href="PedidoServlet?filtro=ENTREGADO" class="btn"
               style="<%= "ENTREGADO".equals(filtroActual) ? "background-color: #27ae60;" : "background-color: #95a5a6;" %>">
               🟢 Entregados
            </a>
            <a href="PedidoServlet?filtro=CANCELADO" class="btn"
               style="<%= "CANCELADO".equals(filtroActual) ? "background-color: #c0392b;" : "background-color: #95a5a6;" %>">
               🔴 Cancelados
            </a>
        </div>

        <% if (pedidos == null || pedidos.isEmpty()) { %>
            <div class="welcome-card">
                <p>No hay pedidos <%= filtroActual != null ? "con estado " + filtroActual : "" %>.</p>
            </div>
        <% } else { %>
            <!-- 🔥 CONTENEDOR CON SCROLL -->
            <div class="tabla-scroll">
                <table>
                    <thead>
                        <tr>
                            <th>#Pedido</th>
                            <th>Fecha</th>
                            <th>👤 Cliente</th>
                            <% if (esAdmin) { %>
                                <th>🧑‍💼 Vendedor</th>
                            <% } %>
                            <th>Total</th>
                            <th>Estado</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Pedido p : pedidos) {
                            String estado = p.getEstado();
                            String colorEstado =
                                "PENDIENTE".equals(estado)  ? "#f39c12" :
                                "CONFIRMADO".equals(estado) ? "#3498db" :
                                "ENTREGADO".equals(estado)  ? "#27ae60" :
                                "CANCELADO".equals(estado)  ? "#c0392b" : "#95a5a6";
                            
                            String clienteNombre = p.getCustomerName() != null ? p.getCustomerName() : "Cliente #" + p.getCustomerId();
                            String clienteEmail  = p.getCustomerEmail() != null ? p.getCustomerEmail() : "";
                            String vendedorNombre = p.getSellerName() != null ? p.getSellerName() : "Vendedor #" + p.getSellerId();
                        %>
                            <tr>
                                <td><b>#<%= p.getOrderId() %></b></td>
                                <td><%= p.getFecha() != null ? sdf.format(p.getFecha()) : "-" %></td>
                                <td>
                                    <b><%= clienteNombre %></b>
                                    <% if (!clienteEmail.isEmpty()) { %>
                                        <br>
                                        <span style="color: #7f8c8d; font-size: 0.85em;">
                                            📧 <%= clienteEmail %>
                                        </span>
                                    <% } %>
                                </td>
                                <% if (esAdmin) { %>
                                    <td><%= vendedorNombre %></td>
                                <% } %>
                                <td><b style="color: #27ae60;">$<%= String.format("%.2f", p.getTotal()) %></b></td>
                                <td>
                                    <span class="badge" style="background-color: <%= colorEstado %>;">
                                        <%= estado %>
                                    </span>
                                </td>
                                <td style="white-space: nowrap;">
                                    <a href="PedidoServlet?accion=verDetalle&id=<%= p.getOrderId() %>"
                                       class="btn"
                                       style="background-color: #34495e; margin-bottom: 5px; display: inline-block;">
                                       👁️ Ver detalle
                                    </a>

                                    <!-- 🔥 NUEVO BOTÓN DE FACTURA PDF -->
                                    <a href="PedidoServlet?accion=verFactura&id=<%= p.getOrderId() %>" 
                                       target="_blank" 
                                       class="btn" 
                                       style="background-color: #e67e22; margin-bottom: 5px; display: inline-block;">
                                       🧾 Factura PDF
                                    </a>

                                    <% if ("PENDIENTE".equals(estado)) { %>
                                        <a href="PedidoServlet?accion=cambiarEstado&id=<%= p.getOrderId() %>&estado=CONFIRMADO"
                                           class="btn"
                                           style="background-color: #3498db; margin-bottom: 5px; display: inline-block;"
                                           onclick="return confirm('¿Confirmar el pedido #<%= p.getOrderId() %>?')">
                                           ✅ Confirmar
                                        </a>
                                    <% } %>

                                    <% if ("CONFIRMADO".equals(estado)) { %>
                                        <a href="PedidoServlet?accion=cambiarEstado&id=<%= p.getOrderId() %>&estado=ENTREGADO"
                                           class="btn"
                                           style="background-color: #27ae60; margin-bottom: 5px; display: inline-block;"
                                           onclick="return confirm('¿Marcar el pedido #<%= p.getOrderId() %> como ENTREGADO?')">
                                           📦 Entregar
                                        </a>
                                    <% } %>

                                    <% if (!"ENTREGADO".equals(estado) && !"CANCELADO".equals(estado)) { %>
                                        <a href="PedidoServlet?accion=cambiarEstado&id=<%= p.getOrderId() %>&estado=CANCELADO"
                                           class="btn-eliminar"
                                           style="margin-bottom: 5px; display: inline-block;"
                                           onclick="return confirm('¿Cancelar el pedido #<%= p.getOrderId() %>?')">
                                           ❌ Cancelar
                                        </a>
                                    <% } %>
                                </td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
            <!-- FIN DEL CONTENEDOR CON SCROLL -->
        <% } %>

        <div style="margin-top: 20px;">
            <a href="menu.jsp" class="btn">← Volver al menú</a>
        </div>
    </main>

</body>
</html>