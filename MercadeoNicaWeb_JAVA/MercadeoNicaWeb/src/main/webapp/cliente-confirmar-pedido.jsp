<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mercadeonica.modelo.*" %>
<%@ page import="com.mercadeonica.dao.TarjetaDAO" %>
<%@ page import="com.mercadeonica.util.MonedaUtil" %>
<%
    Cliente cliente = (Cliente) session.getAttribute("cliente");
    if (cliente == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Carrito carrito = (Carrito) session.getAttribute("carritoCliente");
    if (carrito == null || carrito.estaVacio()) {
        response.sendRedirect("ClienteCarritoServlet");
        return;
    }

    TarjetaDAO tarjetaDAO = new TarjetaDAO();
    List<Tarjeta> tarjetas = tarjetaDAO.listarPorCliente(cliente.getCustomerId());

    double subtotal   = carrito.calcularTotal();
    double descuento  = cliente.getDescuento();
    double montoDesc  = subtotal * (descuento / 100.0);
    double totalFinalUSD = subtotal - montoDesc;

    // 🔥 DETECTAR MONEDA DEL CLIENTE
    String paisCliente = cliente.getEstado() != null ? cliente.getEstado() : "Nicaragua";
    String codigoMoneda = MonedaUtil.getCodigo(paisCliente);
    String simbolo = MonedaUtil.getSimbolo(paisCliente);
    double totalEnMonedaLocal = MonedaUtil.convertirAmonedaLocal(totalFinalUSD, paisCliente);
    double totalEnNIO = MonedaUtil.convertirANIO(totalFinalUSD);

    String error = (String) session.getAttribute("error");
    session.removeAttribute("error");
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
            <a href="cliente-menu.jsp">Mi Cuenta</a>
            <a href="catalogo-publico.jsp">Catálogo</a>
            <a href="ClienteCarritoServlet">Mi Carrito</a>
            <a href="ClienteMisPedidosServlet">Mis Pedidos</a>
            <a href="ClienteTarjetasServlet">Mis Tarjetas</a>
        </nav>
        <div class="user-info">
            <span>👤 <%= cliente.getNombre() %></span>
            <span class="badge" style="background-color: #27ae60;">CLIENTE</span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <h2>✅ Confirmar Pedido</h2>

        <% if (error != null) { %>
            <div class="error">⚠️ <%= error %></div>
        <% } %>

        <div class="welcome-card" style="background:#f8f9fa; border-left:4px solid #27ae60; padding:20px;">
            <h3 style="margin-top:0;">📋 Resumen del pedido</h3>
            <p>Productos: <b><%= carrito.getTamaño() %></b></p>

            <table style="width:100%; margin-top:15px; background:white;">
                <thead>
                    <tr>
                        <th>Producto</th>
                        <th>Precio Unit.</th>
                        <th>Cantidad</th>
                        <th>Subtotal</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (NodoCarrito n : carrito.listar()) { %>
                        <tr>
                            <td><%= n.getProducto().getNombre() %></td>
                            <td>$<%= String.format("%.2f", n.getProducto().getPrecioUnitario()) %></td>
                            <td><%= n.getCantidad() %></td>
                            <td>$<%= String.format("%.2f", n.getSubtotal()) %></td>
                        </tr>
                    <% } %>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan="3" style="text-align:right;">Subtotal:</td>
                        <td style="text-align:right;">$<%= String.format("%.2f", subtotal) %></td>
                    </tr>
                    <% if (descuento > 0) { %>
                        <tr>
                            <td colspan="3" style="text-align:right; color:#e67e22; font-weight:bold;">
                                Descuento (<%= (int) descuento %>%):
                            </td>
                            <td style="text-align:right; color:#e67e22;">
                                -$<%= String.format("%.2f", montoDesc) %>
                            </td>
                        </tr>
                    <% } %>
                    <tr style="background:#eafaf1;">
                        <td colspan="3" style="text-align:right; font-weight:bold; font-size:1.2em;">TOTAL A PAGAR:</td>
                        <td style="text-align:right; font-weight:bold; font-size:1.2em; color:#27ae60;">
                            <%= simbolo %><%= String.format("%.2f", totalEnMonedaLocal) %>
                            <br>
                            <small style="font-size:0.75em; color:#7f8c8d;">(<%= codigoMoneda %>) - Equivalente en C$: <%= String.format("%.2f", totalEnNIO) %></small>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </div>

        <div class="welcome-card" style="background:#eafaf1; border-left:4px solid #27ae60; padding:20px;">
            <h3 style="margin-top:0; color:#1e8449;">👤 Datos del cliente</h3>
            <p><b>Nombre:</b> <%= cliente.getNombre() %></p>
            <p><b>Email:</b> <%= cliente.getEmail() %></p>
            <p><b>País:</b> <%= cliente.getEstado() != null ? cliente.getEstado() : "-" %> (Moneda local: <%= codigoMoneda %>)</p>
            <p><b>Categoría:</b> 
                <span class="badge" style="background-color:#8e44ad;">
                    <%= cliente.getCategoriaNombre() != null ? cliente.getCategoriaNombre() : "Regular" %>
                </span>
                <% if (descuento > 0) { %>
                    <b style="color:#27ae60;">(<%= (int) descuento %>% de descuento)</b>
                <% } %>
            </p>
        </div>

        <div class="form-container">
            <h3 style="margin-top:0;">💳 Datos de pago</h3>
            <form action="ClientePedidoServlet" method="post">

                <div class="form-group">
                    <label>Método de pago:</label>
                    <div style="display:flex; gap:10px; margin-bottom:10px;">
                        <label style="cursor:pointer;"><input type="radio" name="metodoPago" value="tarjeta" checked onclick="toggleTarjeta(true);"> 💳 Tarjeta de Crédito</label>
                        <label style="cursor:pointer;"><input type="radio" name="metodoPago" value="efectivo" onclick="toggleTarjeta(false);"> 💵 Efectivo</label>
                    </div>
                </div>

                <div id="seccionTarjeta">
                    <% if (tarjetas != null && !tarjetas.isEmpty()) { %>
                        <div style="background:#eafaf1; padding:12px; border-radius:6px; margin-bottom:10px;">
                            <label style="display:block; margin-bottom:8px; cursor:pointer;">
                                <input type="radio" name="modoPago" value="guardada" checked
                                       onclick="document.getElementById('ccManual').style.display='none';">
                                <b>Usar tarjeta guardada</b>
                            </label>

                            <% for (Tarjeta t : tarjetas) {
                                boolean expirada = t.isExpirada();
                            %>
                                <label style="display:block; margin: 8px 0 8px 20px; cursor:pointer; <%= expirada ? "opacity:0.5;" : "" %>">
                                    <input type="radio" name="ccSeleccionada"
                                           value="<%= t.getNumero() %>"
                                           <%= expirada ? "disabled" : "" %>
                                           <%= (tarjetas.indexOf(t) == 0 && !expirada) ? "checked" : "" %>>
                                    <b><%= t.getTipo() %></b>
                                    <%= t.getNumeroEnmascarado() %>
                                    (expira <%= t.getFechaExpiracion() %>)
                                </label>
                            <% } %>
                        </div>

                        <label style="display:block; margin-bottom:8px; cursor:pointer;">
                            <input type="radio" name="modoPago" value="nueva"
                                   onclick="document.getElementById('ccManual').style.display='block';">
                            <b>Usar otra tarjeta</b>
                        </label>
                    <% } else { %>
                        <p style="color:#7f8c8d; font-size:0.9em;">
                            ℹ️ No tienes tarjetas guardadas. Puedes pagar en efectivo o 
                            <a href="ClienteTarjetasServlet">guardar una tarjeta</a>.
                        </p>
                        <input type="hidden" name="modoPago" value="nueva">
                    <% } %>

                    <div id="ccManual" style="<%= (tarjetas != null && !tarjetas.isEmpty()) ? "display:none;" : "display:block;" %>">
                        <div class="form-group">
                            <label>Número de tarjeta:</label>
                            <input type="number" name="ccNumber" placeholder="Ej: 1234567890123456" min="1000000000000">
                        </div>

                        <div class="form-group">
                            <label>Tipo de tarjeta:</label>
                            <select name="ccTipo">
                                <option value="">-- Selecciona --</option>
                                <option value="VISA">VISA</option>
                                <option value="MC">MasterCard</option>
                                <option value="AMEX">American Express</option>
                                <option value="Discover">Discover</option>
                            </select>
                        </div>

                        <div style="display:flex; gap:10px;">
                            <div class="form-group" style="flex:1;">
                                <label>Mes exp.:</label>
                                <input type="number" name="ccMes" min="1" max="12">
                            </div>
                            <div class="form-group" style="flex:1;">
                                <label>Año exp.:</label>
                                <input type="number" name="ccAnio" min="2026" max="2100">
                            </div>
                        </div>

                        <label style="display:block; margin:10px 0; cursor:pointer;">
                            <input type="checkbox" name="guardarTarjeta" value="si">
                            💾 Guardar esta tarjeta en mi perfil para futuras compras
                        </label>
                    </div>
                </div>

                <div class="form-group">
                    <label>Fecha del pedido:</label>
                    <input type="date" name="orderDate" required
                           value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>">
                </div>

                <div style="display:flex; gap:10px; margin-top:20px;">
                    <button type="submit" class="btn-primary" style="background-color:#27ae60;">
                        ✅ Confirmar pedido
                    </button>
                    <a href="ClienteCarritoServlet" class="btn" style="background-color:#e67e22;">
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
    </script>
</body>
</html>
