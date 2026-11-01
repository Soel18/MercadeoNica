<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mercadeonica.modelo.Pedido" %>
<%@ page import="com.mercadeonica.modelo.DetallePedido" %>
<%@ page import="com.mercadeonica.modelo.Vendedor" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    Vendedor vendedor = (Vendedor) session.getAttribute("vendedor");
    if (vendedor == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Pedido pedido = (Pedido) request.getAttribute("pedido");
    List<DetallePedido> detalles = (List<DetallePedido>) request.getAttribute("detalles");

    if (pedido == null) {
        response.sendRedirect("PedidoServlet");
        return;
    }

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    boolean esAdmin = vendedor.esAdmin();

    String estado = pedido.getEstado();
    String colorEstado =
        "PENDIENTE".equals(estado)  ? "#f39c12" :
        "CONFIRMADO".equals(estado) ? "#3498db" :
        "ENTREGADO".equals(estado)  ? "#27ae60" :
        "CANCELADO".equals(estado)  ? "#c0392b" : "#95a5a6";
    
    // 🔥 Datos del cliente y vendedor
    String clienteNombre = pedido.getCustomerName() != null ? pedido.getCustomerName() : "Cliente #" + pedido.getCustomerId();
    String clienteEmail  = pedido.getCustomerEmail() != null ? pedido.getCustomerEmail() : "";
    String vendedorNombre = pedido.getSellerName() != null ? pedido.getSellerName() : "Vendedor #" + pedido.getSellerId();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Detalle del Pedido #<%= pedido.getOrderId() %> - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <a href="menu.jsp">Inicio</a>
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
        <h2>🧾 Detalle del Pedido #<%= pedido.getOrderId() %></h2>

        <%-- ============================================================ --%>
        <%-- INFORMACIÓN DEL PEDIDO                                       --%>
        <%-- ============================================================ --%>
        <div class="welcome-card">
            <div style="display: flex; justify-content: space-between; flex-wrap: wrap; gap: 20px;">
                
                <%-- COLUMNA IZQUIERDA: Datos del pedido + cliente --%>
                <div style="flex: 1; min-width: 280px;">
                    <p><b>📅 Fecha:</b> <%= pedido.getFecha() != null ? sdf.format(pedido.getFecha()) : "-" %></p>
                    
                    <%-- 🔥 DATOS DEL CLIENTE (siempre visible) --%>
                    <p>
                        <b>👤 Cliente:</b> 
                        <span style="color: #2c3e50;"><%= clienteNombre %></span>
                        <% if (!clienteEmail.isEmpty()) { %>
                            <br>
                            <span style="color: #7f8c8d; font-size: 0.9em; margin-left: 20px;">
                                📧 <%= clienteEmail %>
                            </span>
                        <% } %>
                    </p>
                    
                    <%-- 🔥 DATOS DEL VENDEDOR (solo admin) --%>
                    <% if (esAdmin) { %>
                        <p>
                            <b>🧑‍💼 Vendedor:</b> 
                            <span style="color: #34495e;"><%= vendedorNombre %></span>
                        </p>
                    <% } %>
                </div>
                
                <%-- COLUMNA DERECHA: Pago + Estado + Total --%>
                <div style="flex: 1; min-width: 280px;">
                    <p><b>💳 Tarjeta:</b> <%= pedido.getCcNumber() %></p>
                    <p>
                        <b>📌 Estado:</b>
                        <span class="badge" style="background-color: <%= colorEstado %>;">
                            <%= estado %>
                        </span>
                    </p>
                    <p style="font-size: 1.3em;">
                        <b>💰 Total:</b>
                        <span style="color: #27ae60;">$<%= String.format("%.2f", pedido.getTotal()) %></span>
                    </p>
                </div>
            </div>
        </div>

        <%-- ============================================================ --%>
        <%-- TABLA DE PRODUCTOS                                           --%>
        <%-- ============================================================ --%>
        <h3>📦 Productos del pedido</h3>

        <% if (detalles == null || detalles.isEmpty()) { %>
            <div class="welcome-card">
                <p>Este pedido no tiene productos registrados.</p>
            </div>
        <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Producto</th>
                        <th>Precio Unit.</th>
                        <th>Cantidad</th>
                        <th>Subtotal</th>
                    </tr>
                </thead>
                <tbody>
                    <% int i = 1; for (DetallePedido d : detalles) { %>
                        <tr>
                            <td><%= i++ %></td>
                            <td><b><%= d.getProducto().getNombre() %></b></td>
                            <td>$<%= String.format("%.2f", d.getPrecioUnitario()) %></td>
                            <td><%= d.getCantidad() %></td>
                            <td><b>$<%= String.format("%.2f", d.getSubtotal()) %></b></td>
                        </tr>
                    <% } %>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan="4" style="text-align: right; font-weight: bold;">TOTAL:</td>
                        <td style="font-weight: bold; color: #27ae60; font-size: 1.1em;">
                            $<%= String.format("%.2f", pedido.getTotal()) %>
                        </td>
                    </tr>
                </tfoot>
            </table>
        <% } %>

        <%-- ============================================================ --%>
        <%-- ACCIONES                                                    --%>
        <%-- ============================================================ --%>
        <div style="margin-top: 30px; display: flex; gap: 10px; flex-wrap: wrap;">
            <a href="PedidoServlet" class="btn">← Volver a la lista</a>

            <% if ("PENDIENTE".equals(estado)) { %>
                <a href="PedidoServlet?accion=cambiarEstado&id=<%= pedido.getOrderId() %>&estado=CONFIRMADO"
                   class="btn"
                   style="background-color: #3498db;"
                   onclick="return confirm('¿Confirmar este pedido?')">
                   ✅ Confirmar pedido
                </a>
            <% } %>

            <% if ("CONFIRMADO".equals(estado)) { %>
                <a href="PedidoServlet?accion=cambiarEstado&id=<%= pedido.getOrderId() %>&estado=ENTREGADO"
                   class="btn"
                   style="background-color: #27ae60;"
                   onclick="return confirm('¿Marcar como ENTREGADO?')">
                   📦 Marcar como Entregado
                </a>
            <% } %>

            <% if (!"ENTREGADO".equals(estado) && !"CANCELADO".equals(estado)) { %>
                <a href="PedidoServlet?accion=cambiarEstado&id=<%= pedido.getOrderId() %>&estado=CANCELADO"
                   class="btn-eliminar"
                   onclick="return confirm('¿Cancelar este pedido?')">
                   ❌ Cancelar pedido
                </a>
            <% } %>
        </div>
    </main>

</body>
</html>