<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.mercadeonica.modelo.Producto" %>
<%@ page import="com.mercadeonica.modelo.Categoria" %>
<%@ page import="com.mercadeonica.modelo.Vendedor" %>
<%
    Vendedor vendedor = (Vendedor) session.getAttribute("vendedor");
    if (vendedor == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Producto> productos   = (List<Producto>) request.getAttribute("productos");
    List<Categoria> categorias = (List<Categoria>) request.getAttribute("categorias");
    Producto productoEditar    = (Producto) request.getAttribute("productoEditar");
    String mensaje = (String) request.getAttribute("mensaje");
    boolean esAdmin = vendedor.esAdmin();

    String filtroQ         = (String) request.getAttribute("filtroQ");
    String filtroCategoria = (String) request.getAttribute("filtroCategoria");
    String filtroMin       = (String) request.getAttribute("filtroPrecioMin");
    String filtroMax       = (String) request.getAttribute("filtroPrecioMax");
    Boolean filtroSoloDisp = (Boolean) request.getAttribute("filtroSoloDisponibles");
    String filtroOrden     = (String) request.getAttribute("filtroOrden");
    String filtroResenas   = (String) request.getAttribute("filtroResenas");
    if (filtroQ == null) filtroQ = "";
    if (filtroCategoria == null) filtroCategoria = "";
    if (filtroMin == null) filtroMin = "";
    if (filtroMax == null) filtroMax = "";
    if (filtroSoloDisp == null) filtroSoloDisp = false;
    if (filtroOrden == null) filtroOrden = "reciente";
    if (filtroResenas == null) filtroResenas = "todas";

    int totalProductos = productos != null ? productos.size() : 0;
    Map<Integer, Double> promedios = new com.mercadeonica.dao.ResenaDAO().obtenerPromedios();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Productos - MercadeoNica</title>
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
            <a href="ProductoServlet"><b>Productos</b></a>
            <a href="ClienteServlet">Clientes</a>
            <a href="carrito.jsp">Carrito</a>
            <a href="PedidoServlet">Pedidos</a>
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

        <% if (productoEditar != null) { %>
            <div class="form-container" style="border: 3px solid #3498db; background: #eaf4fc; margin-bottom: 25px;">
                <h2 style="color: #2980b9; margin-top: 0;">✏️ Editar Producto #<%= productoEditar.getProductId() %></h2>
                <p style="color: #7f8c8d; margin-bottom: 15px;">
                    Modifica los datos que necesites y presiona <b>Guardar cambios</b>.
                </p>

                <form action="ProductoServlet" method="post">
                    <input type="hidden" name="accion" value="guardarEdicion">
                    <input type="hidden" name="productId" value="<%= productoEditar.getProductId() %>">

                    <div class="form-group">
                        <label>Nombre del producto:</label>
                        <input type="text" name="nombre" required
                               value="<%= productoEditar.getNombre() != null ? productoEditar.getNombre() : "" %>">
                    </div>

                    <div class="form-group">
                        <label>Precio unitario:</label>
                        <input type="number" step="0.01" min="0.01" name="precio" required
                               value="<%= productoEditar.getPrecioUnitario() %>">
                    </div>

                    <div class="form-group">
                        <label>Categoría:</label>
                        <select name="categoriaId" required>
                            <% if (categorias != null) for (Categoria c : categorias) { 
                                String sel = (c.getCategoryId() == productoEditar.getCategoriaId()) ? "selected" : "";
                            %>
                                <option value="<%= c.getCategoryId() %>" <%= sel %>>
                                    <%= c.getNombre() %>
                                </option>
                            <% } %>
                        </select>
                    </div>

                    <div style="display: flex; gap: 10px; margin-top: 20px;">
                        <button type="submit" class="btn-primary" style="background-color: #2980b9;">
                            💾 Guardar cambios
                        </button>
                        <a href="ProductoServlet" class="btn" style="background-color: #95a5a6;">
                            Cancelar
                        </a>
                    </div>
                </form>
            </div>
        <% } %>

        <h2>Catálogo de Productos</h2>

        <div class="form-container" style="background:#f8f9fa; margin-bottom:20px;">
            <form action="ProductoServlet" method="get">
                <div style="display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 12px;">
                    <div style="flex: 2; min-width: 200px;">
                        <label style="font-weight: 500;">🔍 Buscar:</label>
                        <input type="text" name="q" value="<%= filtroQ %>"
                               placeholder="Nombre del producto..."
                               style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                    </div>

                    <div style="flex: 1; min-width: 180px;">
                        <label style="font-weight: 500;">🏷️ Categoría:</label>
                        <select name="categoria" style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                            <option value="">Todas las categorías</option>
                            <% if (categorias != null) for (Categoria c : categorias) {
                                String sel = String.valueOf(c.getCategoryId()).equals(filtroCategoria) ? "selected" : "";
                            %>
                                <option value="<%= c.getCategoryId() %>" <%= sel %>>
                                    <%= c.getNombre() %>
                                </option>
                            <% } %>
                        </select>
                    </div>
                </div>

                <div style="display: flex; gap: 10px; flex-wrap: wrap; align-items: end;">
                    <div style="min-width: 120px;">
                        <label style="font-weight: 500;">💵 Precio mín:</label>
                        <input type="number" name="precioMin" step="0.01" min="0"
                               value="<%= filtroMin %>" placeholder="$0"
                               style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                    </div>

                    <div style="min-width: 120px;">
                        <label style="font-weight: 500;">💵 Precio máx:</label>
                        <input type="number" name="precioMax" step="0.01" min="0"
                               value="<%= filtroMax %>" placeholder="$9999"
                               style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                    </div>

                    <div style="min-width: 180px;">
                        <label style="font-weight: 500;">⭐ Filtrar por reseñas:</label>
                        <select name="resenas" style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                            <option value="todas" <%= "todas".equals(filtroResenas) ? "selected" : "" %>>Todas</option>
                            <option value="5"     <%= "5".equals(filtroResenas)     ? "selected" : "" %>>⭐⭐⭐⭐⭐ Solo 5 estrellas</option>
                            <option value="4"     <%= "4".equals(filtroResenas)     ? "selected" : "" %>>⭐⭐⭐⭐ 4+ estrellas</option>
                            <option value="3"     <%= "3".equals(filtroResenas)     ? "selected" : "" %>>⭐⭐⭐ 3+ estrellas</option>
                            <option value="2"     <%= "2".equals(filtroResenas)     ? "selected" : "" %>>⭐⭐ 2+ estrellas</option>
                            <option value="sin"   <%= "sin".equals(filtroResenas)   ? "selected" : "" %>>❌ Sin reseñas</option>
                        </select>
                    </div>

                    <div style="min-width: 200px;">
                        <label style="font-weight: 500;">📊 Ordenar por:</label>
                        <select name="orden" style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                            <option value="reciente"          <%= "reciente".equals(filtroOrden)          ? "selected" : "" %>>Más reciente</option>
                            <option value="nombre"            <%= "nombre".equals(filtroOrden)            ? "selected" : "" %>>Nombre (A-Z)</option>
                            <option value="precio_asc"        <%= "precio_asc".equals(filtroOrden)        ? "selected" : "" %>>Precio: menor a mayor</option>
                            <option value="precio_desc"       <%= "precio_desc".equals(filtroOrden)       ? "selected" : "" %>>Precio: mayor a menor</option>
                            <option value="mejor_calificado"  <%= "mejor_calificado".equals(filtroOrden)  ? "selected" : "" %>>⭐ Mejor calificados</option>
                            <option value="peor_calificado"   <%= "peor_calificado".equals(filtroOrden)   ? "selected" : "" %>>⭐ Peor calificados</option>
                        </select>
                    </div>

                    <div style="padding-bottom: 8px;">
                        <label style="cursor:pointer;">
                            <input type="checkbox" name="soloDisponibles" <%= filtroSoloDisp ? "checked" : "" %>>
                            Solo con stock
                        </label>
                    </div>
                </div>

                <div style="margin-top: 15px; display: flex; gap: 10px;">
                    <button type="submit" class="btn-primary">🔍 Buscar</button>
                    <a href="ProductoServlet" class="btn" style="background-color: #95a5a6;">🔄 Limpiar</a>
                </div>
            </form>
        </div>

        <p style="color: #7f8c8d; margin-bottom: 10px;">
            📦 <b><%= totalProductos %></b> producto(s) encontrado(s)
        </p>

        <!-- 🔥 CONTENEDOR CON SCROLL -->
        <div class="tabla-scroll">
            <table>
                <thead>
                    <tr>
                        <% if (esAdmin) { %><th>ID</th><% } %>
                        <th>Producto</th>
                        <th>Categoría</th>
                        <th>Stock</th>
                        <th>Precio</th>
                        <th>⭐ Reseñas</th>
                        <th>Acciones</th>
                        <th>Carrito</th>
                    </tr>
                </thead>
                                <tbody>
                    <% if (productos != null && !productos.isEmpty()) {
                        for (Producto p : productos) { 
                            // 🔥 LÓGICA DE COLORES POR STOCK
                            int stock = p.getCantidadDisponible();
                            String estiloFila = "";
                            String textoEstado = "";
                            
                            if (stock == 0) {
                                estiloFila = "background-color: #fdecea;"; // Rojo suave
                                textoEstado = "<span style='color:#c0392b; font-size:0.8em;'>⚠️ AGOTADO</span>";
                            } else if (stock < 50) {
                                estiloFila = "background-color: #fef9e7;"; // Amarillo suave
                                textoEstado = "<span style='color:#f39c12; font-size:0.8em;'>📉 BAJO STOCK</span>";
                            }
                    %>
                        <tr style="<%= estiloFila %>">
                            <% if (esAdmin) { %><td><%= p.getProductId() %></td><% } %>
                            <td>
                                <b><%= p.getNombre() %></b><br>
                                <%= textoEstado %> <!-- 🔥 Etiqueta de alerta -->
                            </td>
                            <td><%= p.getCategoriaNombre() != null ? p.getCategoriaNombre() : "-" %></td>
                            <td>
                                <% if (esAdmin) { %>
                                    <form action="ProductoServlet" method="post"
                                          style="display: flex; align-items: center; gap: 5px; margin: 0;">
                                        <input type="hidden" name="accion" value="actualizarStock">
                                        <input type="hidden" name="productId" value="<%= p.getProductId() %>">
                                        <input type="number" name="nuevoStock"
                                               value="<%= p.getCantidadDisponible() %>" min="0"
                                               style="width: 75px; padding: 5px; text-align: center; border: <%= stock < 50 ? "2px solid " + (stock == 0 ? "#c0392b" : "#f39c12") : "1px solid #ccc" %>;">
                                        <button type="submit" class="btn"
                                                style="background-color: #27ae60; padding: 5px 10px; font-size: 0.85em;">
                                            💾
                                        </button>
                                    </form>
                                <% } else { %>
                                    <b style="color: <%= stock == 0 ? "#c0392b" : (stock < 50 ? "#f39c12" : "#333") %>;">
                                        <%= stock %>
                                    </b>
                                <% } %>
                            </td>
                            <td>$<%= String.format("%.2f", p.getPrecioUnitario()) %></td>

                            <td>
                                <% Double prom = promedios.get(p.getProductId());
                                   if (prom != null && prom > 0) { %>
                                    <b style="color: #f39c12;"><%= String.format("%.1f", prom) %> ⭐</b>
                                <% } else { %>
                                    <span style="color: #999; font-size: 0.85em;">Sin reseñas</span>
                                <% } %>
                            </td>

                            <td style="white-space: nowrap;">
                                <a href="ProductoServlet?accion=editar&id=<%= p.getProductId() %>"
                                   class="btn"
                                   style="background-color: #3498db; margin-bottom: 5px; display: inline-block;">
                                   ✏️ Editar
                                </a>

                                <% if (esAdmin) { %>
                                    <a href="ProductoServlet?accion=eliminar&id=<%= p.getProductId() %>"
                                       class="btn-eliminar"
                                       style="margin-bottom: 5px; display: inline-block;"
                                       onclick="return confirm('¿Eliminar este producto?')">Eliminar</a>
                                <% } %>
                            </td>
                            <td>
                                <form action="CarritoServlet" method="post" style="display:flex; gap:5px; align-items:center;">
                                    <input type="hidden" name="accion" value="agregar">
                                    <input type="hidden" name="productId" value="<%= p.getProductId() %>">
                                    <input type="number" name="cantidad" value="1" min="1" max="<%= p.getCantidadDisponible() %>" style="width:60px; padding:5px;">
                                    <button type="submit" class="btn" <%= stock == 0 ? "disabled" : "" %>>
                                        <%= stock == 0 ? "Agotado" : "Agregar" %>
                                    </button>
                                </form>
                            </td>
                        </tr>
                    <% }} else { %>
                        <tr><td colspan="8" style="text-align:center; color:#7f8c8d; padding:20px;">
                            No se encontraron productos con esos filtros.
                        </td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <!-- FIN DEL CONTENEDOR CON SCROLL -->

        <h2>➕ Agregar nuevo producto</h2>
        <div class="form-container">
            <form action="ProductoServlet" method="post">
                <input type="hidden" name="accion" value="agregar">

                <div class="form-group">
                    <label>Nombre del producto:</label>
                    <input type="text" name="nombre" required>
                </div>

                <div class="form-group">
                    <label>Cantidad disponible:</label>
                    <input type="number" name="cantidad" min="1" required>
                </div>

                <div class="form-group">
                    <label>Precio unitario:</label>
                    <input type="number" name="precio" step="0.01" min="0.01" required>
                </div>

                <div class="form-group">
                    <label>Categoría:</label>
                    <div style="display: flex; gap: 10px; align-items: center;">
                        <select name="categoria" required style="flex: 1;">
                            <option value="">-- Selecciona una categoría --</option>
                            <% if (categorias != null) for (Categoria c : categorias) { %>
                                <option value="<%= c.getNombre() %>"><%= c.getNombre() %></option>
                            <% } %>
                        </select>

                        <% if (esAdmin) { %>
                            <button type="button" class="btn" style="background-color: #9b59b6; white-space: nowrap;"
                                    onclick="toggleNuevaCategoria()">
                                ➕ Nueva Categoría
                            </button>
                        <% } %>
                    </div>
                </div>

                <button type="submit" class="btn-primary">Agregar producto</button>
            </form>
        </div>

        <% if (esAdmin) { %>
            <div id="formNuevaCategoria" style="display: none;">
                <div class="form-container" style="border: 3px solid #9b59b6; background: #fef9ff;">
                    <h2 style="color: #9b59b6;">➕ Agregar Nueva Categoría</h2>

                    <form action="ProductoServlet" method="post">
                        <input type="hidden" name="accion" value="agregarCategoria">

                        <div class="form-group">
                            <label>Nombre de la categoría:</label>
                            <input type="text" name="nombreCategoria" required maxlength="50">
                        </div>

                        <div class="form-group">
                            <label>Descripción (opcional):</label>
                            <input type="text" name="descripcionCategoria" maxlength="150">
                        </div>

                        <div style="display: flex; gap: 10px; margin-top: 20px;">
                            <button type="submit" class="btn-primary" style="background-color: #9b59b6;">
                                ✅ Guardar categoría
                            </button>
                            <button type="button" class="btn" onclick="toggleNuevaCategoria()">
                                Cancelar
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        <% } %>
    </main>

    <script>
        function toggleNuevaCategoria() {
            var form = document.getElementById('formNuevaCategoria');
            if (form) {
                form.style.display = (form.style.display === 'none' || form.style.display === '') ? 'block' : 'none';
                if (form.style.display === 'block') {
                    form.scrollIntoView({ behavior: 'smooth', block: 'top' });
                }
            }
        }
    </script>

</body>
</html>