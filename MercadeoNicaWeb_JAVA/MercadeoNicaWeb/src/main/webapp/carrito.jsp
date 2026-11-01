<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.mercadeonica.modelo.*" %>
<%@ page import="java.util.List" %>
<%
    Vendedor vendedor = (Vendedor) session.getAttribute("vendedor");
    if (vendedor == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Carrito carrito = (Carrito) session.getAttribute("carrito");
    if (carrito == null) {
        carrito = new Carrito();
        session.setAttribute("carrito", carrito);
    }

    // 🔥 Intentar obtener los clientes del request
    List<Cliente> clientes = (List<Cliente>) request.getAttribute("clientes");
    
    // 🔥 FALLBACK: Si el Servlet no los envió, cargarlos aquí directamente
    if (clientes == null || clientes.isEmpty()) {
        com.mercadeonica.dao.ClienteDAO daoClientes = new com.mercadeonica.dao.ClienteDAO();
        clientes = daoClientes.listar();
        System.out.println("🔧 [carrito.jsp] Fallback activado: " + clientes.size() + " clientes cargados");
    } else {
        System.out.println("✅ [carrito.jsp] Clientes recibidos del Servlet: " + clientes.size());
    }
    
    Cliente clienteActual = carrito.getCliente();
    String mensaje = (String) request.getAttribute("mensaje");
    String error   = (String) request.getAttribute("error");

    // ============================================================
    // CONSTRUIR EL JSON DE CLIENTES
    // ============================================================
    StringBuilder clientesJson = new StringBuilder("[");
    if (clientes != null) {
        for (int i = 0; i < clientes.size(); i++) {
            Cliente c = clientes.get(i);
            if (i > 0) clientesJson.append(",");
            
            String nombre = c.getNombre() != null ? c.getNombre().replace("\\", "\\\\").replace("\"", "\\\"") : "";
            String email  = c.getEmail() != null ? c.getEmail().replace("\\", "\\\\").replace("\"", "\\\"") : "";
            String catNom = c.getCategoriaNombre() != null ? c.getCategoriaNombre().replace("\\", "\\\\").replace("\"", "\\\"") : "Sin categoría";
            
            clientesJson.append("{\"id\":").append(c.getCustomerId())
                .append(",\"nombre\":\"").append(nombre).append("\"")
                .append(",\"email\":\"").append(email).append("\"")
                .append(",\"categoria\":\"").append(catNom).append("\"")
                .append(",\"descuento\":").append(c.getDescuento())
                .append("}");
        }
    }
    clientesJson.append("]");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Carrito - MercadeoNica</title>
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
        <h2>🛒 Carrito de Compras</h2>

        <% if (mensaje != null) { %>
            <div class="ok">✅ <%= mensaje %></div>
        <% } %>
        
        <% if (error != null) { %>
            <div style="background:#fadbd8; border-left:4px solid #e74c3c; padding:12px; margin-bottom:15px; border-radius:4px; color:#922b21;">
                ❌ <%= error %>
            </div>
        <% } %>

        <% if (clienteActual == null) { %>

            <div class="welcome-card" style="background: #fef9e7; border-left: 4px solid #f39c12; padding: 20px;">
                <h3 style="margin-top: 0; color: #b9770e;">👤 Paso 1: Selecciona un cliente</h3>
                <p style="color: #7f8c8d;">
                    Antes de agregar productos, debes elegir el cliente al que se le asignará la venta.
                    Se aplicará automáticamente el descuento según su categoría.
                </p>

                <div style="background: white; padding: 15px; border-radius: 6px; margin-top: 15px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
                    <label style="font-weight: bold; display: block; margin-bottom: 8px;">
                        🔍 Buscar cliente por nombre o email:
                    </label>
                    
                    <input type="text" 
                           id="buscarCliente" 
                           placeholder="Escribe para buscar (Ej: Franklin, sofia@gmail.com...)"
                           autocomplete="off"
                           style="width: 100%; padding: 10px; font-size: 1em; border: 2px solid #f39c12; border-radius: 4px; box-sizing: border-box;"
                           onkeyup="filtrarClientes()">

                    <div id="sugerencias" 
                         style="max-height: 250px; overflow-y: auto; margin-top: 10px; border: 1px solid #ddd; border-radius: 4px; display: none;">
                    </div>
                </div>

                <form action="CarritoServlet" method="get" style="display: flex; gap: 10px; align-items: center; margin-top: 15px;">
                    <input type="hidden" name="accion" value="seleccionarCliente">
                    <input type="hidden" name="customerId" id="customerIdSeleccionado" value="">
                    
                    <div style="flex: 1; padding: 12px; background: #f8f9fa; border: 1px dashed #ccc; border-radius: 4px;" id="clienteElegido">
                        <span style="color: #7f8c8d;">Ningún cliente seleccionado</span>
                    </div>

                    <button type="submit" 
                            class="btn-primary" 
                            id="btnSeleccionar"
                            style="padding: 12px 24px; opacity: 0.5;" 
                            disabled>
                        Seleccionar
                    </button>
                </form>
            </div>

        <% } else { %>

            <div class="welcome-card" style="background: #eafaf1; border-left: 4px solid #27ae60; padding: 15px 20px; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <h3 style="margin: 0; color: #1e8449;">👤 Cliente: <%= clienteActual.getNombre() %></h3>
                    <p style="margin: 5px 0 0 0; color: #7f8c8d; font-size: 0.95em;">
                        📧 <%= clienteActual.getEmail() %> |
                        🏷️ Categoría: <b><%= clienteActual.getCategoriaNombre() != null ? clienteActual.getCategoriaNombre() : "Sin categoría" %></b>
                        <% if (clienteActual.getDescuento() > 0) { %>
                            | 💰 Descuento: <b style="color: #27ae60;"><%= (int) clienteActual.getDescuento() %>%</b>
                        <% } %>
                    </p>
                </div>
                <a href="CarritoServlet?accion=quitarCliente"
                   class="btn"
                   style="background-color: #e67e22; white-space: nowrap;"
                   onclick="return confirm('¿Cambiar de cliente? Se quitará el cliente actual pero se mantendrán los productos.')">
                    🔄 Cambiar cliente
                </a>
            </div>

            <% if (carrito.estaVacio()) { %>
                <div class="welcome-card" style="text-align: center; padding: 40px; margin-top: 20px;">
                    <p style="font-size: 1.1em; color: #7f8c8d;">El carrito está vacío.</p>
                    <p>Ve a <a href="ProductoServlet"><b>Productos</b></a> para agregar artículos.</p>
                </div>
            <% } else { %>
                <table style="margin-top: 20px;">
                    <thead>
                        <tr>
                            <th>Producto</th>
                            <th>Precio Unit.</th>
                            <th>Cantidad</th>
                            <th>Subtotal</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (NodoCarrito n : carrito.listar()) { %>
                            <tr>
                                <td><b><%= n.getProducto().getNombre() %></b></td>
                                <td>$<%= String.format("%.2f", n.getProducto().getPrecioUnitario()) %></td>
                                <td><%= n.getCantidad() %></td>
                                <td>$<%= String.format("%.2f", n.getSubtotal()) %></td>
                                <td>
                                    <a href="CarritoServlet?accion=eliminar&productId=<%= n.getProducto().getProductId() %>"
                                       class="btn-eliminar"
                                       onclick="return confirm('¿Eliminar este producto?')">Eliminar</a>
                                </td>
                            </tr>
                        <% } %>
                    </tbody>
                    <tfoot>
                        <tr>
                            <td colspan="3" style="text-align:right; font-weight:bold; padding-top: 15px;">Subtotal:</td>
                            <td colspan="2" style="text-align:right; padding-top: 15px;">
                                $<%= String.format("%.2f", carrito.calcularTotal()) %>
                            </td>
                        </tr>
                        <% if (clienteActual.getDescuento() > 0) { %>
                            <tr>
                                <td colspan="3" style="text-align:right; font-weight:bold; color: #e67e22;">
                                    Descuento (<%= (int) clienteActual.getDescuento() %>%):
                                </td>
                                <td colspan="2" style="text-align:right; color: #e67e22;">
                                    -$<%= String.format("%.2f", carrito.calcularDescuento()) %>
                                </td>
                            </tr>
                        <% } %>
                        <tr style="background: #f8f9fa;">
                            <td colspan="3" style="text-align:right; font-weight:bold; font-size: 1.2em;">TOTAL:</td>
                            <td colspan="2" style="text-align:right; font-weight:bold; font-size: 1.2em; color:#27ae60;">
                                $<%= String.format("%.2f", carrito.calcularTotalConDescuento()) %>
                            </td>
                        </tr>
                    </tfoot>
                </table>

                <div style="margin-top: 20px; display:flex; gap: 10px; flex-wrap: wrap;">
                    <a href="ProductoServlet" class="btn">← Seguir agregando</a>
                    <a href="CarritoServlet?accion=vaciar" class="btn-eliminar"
                       onclick="return confirm('¿Vaciar todos los productos del carrito?')">🗑️ Vaciar carrito</a>
                    <a href="pedido-form.jsp" class="btn-primary" style="background-color: #27ae60;">
                        ✅ Confirmar pedido →
                    </a>
                </div>
            <% } %>
        <% } %>

    </main>

    <script>
        var clientesData = <%= clientesJson.toString() %>;
        console.log("📋 Clientes cargados en el JSP:", clientesData.length);

        function filtrarClientes() {
            var texto = document.getElementById('buscarCliente').value.toLowerCase().trim();
            var div = document.getElementById('sugerencias');
            
            if (texto.length === 0) {
                div.style.display = 'none';
                div.innerHTML = '';
                return;
            }

            var coincidencias = clientesData.filter(function(c) {
                var nombre = (c.nombre || '').toLowerCase();
                var email  = (c.email || '').toLowerCase();
                return nombre.indexOf(texto) !== -1 || email.indexOf(texto) !== -1;
            });

            if (coincidencias.length === 0) {
                div.innerHTML = '<div style="padding: 12px; color: #7f8c8d; text-align: center;">Sin resultados</div>';
                div.style.display = 'block';
                return;
            }

            coincidencias = coincidencias.slice(0, 10);

            var html = '';
            coincidencias.forEach(function(c) {
                var badgeColor = c.descuento >= 20 ? '#8e44ad' :
                                 c.descuento >= 15 ? '#f39c12' :
                                 c.descuento >= 10 ? '#95a5a6' :
                                 c.descuento >= 5  ? '#cd7f32' : '#7f8c8d';
                var nombre = c.nombre || '(Sin nombre)';
                var email  = c.email  || '(Sin email)';
                html += '<div onclick="seleccionarCliente(' + c.id + ')" ' +
                        'style="padding: 10px 15px; cursor: pointer; border-bottom: 1px solid #eee;" ' +
                        'onmouseover="this.style.background=\'#fef9e7\'" ' +
                        'onmouseout="this.style.background=\'white\'">' +
                        '<b>' + nombre + '</b> ' +
                        '<span style="color: #7f8c8d;">(' + email + ')</span> ' +
                        '<span style="background:' + badgeColor + '; color:white; padding:2px 8px; border-radius:10px; font-size:0.8em; margin-left:8px;">' +
                            (c.categoria || 'Sin categoría') + (c.descuento > 0 ? ' - ' + c.descuento + '%' : '') +
                        '</span>' +
                        '</div>';
            });

            div.innerHTML = html;
            div.style.display = 'block';
        }

        function seleccionarCliente(id) {
            var cliente = null;
            for (var i = 0; i < clientesData.length; i++) {
                if (clientesData[i].id === id) {
                    cliente = clientesData[i];
                    break;
                }
            }
            if (!cliente) return;

            document.getElementById('customerIdSeleccionado').value = id;

            document.getElementById('clienteElegido').innerHTML = 
                '✅ <b>' + cliente.nombre + '</b> ' +
                '<span style="color: #7f8c8d;">(' + cliente.email + ')</span> ' +
                '<span style="color: #27ae60; font-weight: bold;"> - ' + 
                (cliente.categoria || 'Sin categoría') + (cliente.descuento > 0 ? ' (' + cliente.descuento + '% desc.)' : '') +
                '</span>';

            document.getElementById('sugerencias').style.display = 'none';
            document.getElementById('buscarCliente').value = cliente.nombre;

            var btn = document.getElementById('btnSeleccionar');
            btn.disabled = false;
            btn.style.opacity = '1';
        }
    </script>

</body>
</html>