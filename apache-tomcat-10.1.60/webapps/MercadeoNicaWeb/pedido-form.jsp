<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.mercadeonica.modelo.*" %>
<%@ page import="com.mercadeonica.util.MonedaUtil" %>
<%
    Vendedor vendedor = (Vendedor) session.getAttribute("vendedor");
    if (vendedor == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Carrito carrito = (Carrito) session.getAttribute("carrito");
    if (carrito == null || carrito.estaVacio()) {
        response.sendRedirect("CarritoServlet");
        return;
    }

    Cliente cliente = carrito.getCliente();
    if (cliente == null) {
        response.sendRedirect("CarritoServlet");
        return;
    }

    double totalOriginal = carrito.calcularTotal();
    double descuento     = carrito.calcularDescuento();
    double totalFinalUSD = carrito.calcularTotalConDescuento();
    int    items         = carrito.getTamaño();

    // 🔥 MONEDA SEGÚN EL PAÍS DEL CLIENTE
    String paisCliente = cliente.getEstado() != null ? cliente.getEstado() : "Nicaragua";
    String codigoMoneda = MonedaUtil.getCodigo(paisCliente);
    String simbolo      = MonedaUtil.getSimbolo(paisCliente);
    double totalEnMonedaLocal = MonedaUtil.convertirAmonedaLocal(totalFinalUSD, paisCliente);
    double totalEnNIO         = MonedaUtil.convertirANIO(totalFinalUSD);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Confirmar Pedido - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <a href="menu.jsp">Inicio</a>
            <a href="ProductoServlet">Productos</a>
            <a href="ClienteServlet">Clientes</a>
            <a href="CarritoServlet"><b>Carrito</b></a>
            <a href="PedidoServlet">Pedidos</a>
        </nav>
        <div class="user-info">
            <span>👤 <%= vendedor.getNombre() %></span>
            <span class="badge"><%= vendedor.getRol() %></span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <h2>✅ Confirmar Pedido</h2>

        <div class="welcome-card" style="background:#f8f9fa; border-left:4px solid #27ae60; padding:20px; margin-bottom:20px;">
            <h3 style="margin-top:0;">📋 Resumen del carrito</h3>
            <p>Productos: <b><%= items %></b></p>
            <p style="font-size:1.1em;">
                Subtotal: <b>$<%= String.format("%.2f", totalOriginal) %></b>
            </p>
            <% if (descuento > 0) { %>
                <p style="color:#e67e22;">
                    Descuento (<%= (int) cliente.getDescuento() %>%):
                    <b>-$<%= String.format("%.2f", descuento) %></b>
                </p>
            <% } %>
            <p style="font-size:1.3em; color:#27ae60;">
                Total a pagar: <b><%= simbolo %><%= String.format("%.2f", totalEnMonedaLocal) %></b>
                <br>
                <small style="font-size:0.75em; color:#7f8c8d;">
                    (<%= codigoMoneda %>) - Equivalente en C$: <%= String.format("%.2f", totalEnNIO) %>
                </small>
            </p>
        </div>

        <div class="welcome-card" style="background:#eafaf1; border-left:4px solid #27ae60; padding:20px; margin-bottom:20px;">
            <h3 style="margin-top:0; color:#1e8449;">👤 Datos del cliente</h3>
            <p><b>Nombre:</b> <%= cliente.getNombre() %></p>
            <p><b>Email:</b> <%= cliente.getEmail() %></p>
            <p><b>País:</b> <%= paisCliente %> (Moneda local: <%= codigoMoneda %>)</p>
            <p><b>Categoría:</b>
                <span style="background:#8e44ad; color:white; padding:3px 10px; border-radius:12px; font-size:0.85em;">
                    <%= cliente.getCategoriaNombre() != null ? cliente.getCategoriaNombre() : "Sin categoría" %>
                </span>
                <% if (cliente.getDescuento() > 0) { %>
                    <b style="color:#27ae60;">(<%= (int) cliente.getDescuento() %>% de descuento)</b>
                <% } %>
            </p>
            <p style="font-size:0.9em; color:#7f8c8d; margin-bottom:0;">
                💡 Si necesitas cambiar de cliente,
                <a href="CarritoServlet?accion=quitarCliente">regresa al carrito</a>
                y selecciona otro.
            </p>
        </div>

        <div class="form-container">
            <h3 style="margin-top:0;">💳 Datos de pago</h3>
            <form action="PedidoServlet" method="post">

                <div class="form-group">
                    <label>Método de pago:</label>
                    <div style="display:flex; gap:10px; margin-bottom:10px;">
                        <label style="cursor:pointer;">
                            <input type="radio" name="metodoPago" value="tarjeta" checked onclick="toggleTarjeta(true);"> 💳 Tarjeta
                        </label>
                        <label style="cursor:pointer;">
                            <input type="radio" name="metodoPago" value="efectivo" onclick="toggleTarjeta(false);"> 💵 Efectivo
                        </label>
                    </div>
                </div>

                <div id="seccionTarjeta">
                    <div class="form-group">
                        <label>Número de tarjeta:</label>
                        <input type="number" name="ccNumber"
                               placeholder="Ej: 1234567890123456"
                               min="1000000000000">
                    </div>
                </div>

                <div class="form-group">
                    <label>Fecha del pedido:</label>
                    <input type="date" name="orderDate" required>
                </div>

                <div style="display:flex; gap:10px; margin-top:20px;">
                    <button type="submit" class="btn-primary" style="background-color:#27ae60;">
                        ✅ Confirmar pedido
                    </button>
                    <a href="CarritoServlet" class="btn" style="background-color:#e67e22;">
                        Cancelar
                    </a>
                </div>
            </form>
        </div>
    </main>

    <script>
        function toggleTarjeta(mostrar) {
            document.getElementById('seccionTarjeta').style.display = mostrar ? 'block' : 'none';
        }
        document.addEventListener('DOMContentLoaded', function() {
            var fechaInput = document.querySelector('input[name="orderDate"]');
            if (fechaInput && !fechaInput.value) {
                var hoy = new Date();
                var yyyy = hoy.getFullYear();
                var mm = String(hoy.getMonth() + 1).padStart(2, '0');
                var dd = String(hoy.getDate()).padStart(2, '0');
                fechaInput.value = yyyy + '-' + mm + '-' + dd;
            }
        });
    </script>
</body>
</html>