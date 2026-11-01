package com.mercadeonica.controlador;

import com.mercadeonica.dao.CategoriaDAO;
import com.mercadeonica.dao.ProductoDAO;
import com.mercadeonica.modelo.Producto; // 🔥 Importante

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet(name = "ProductoServlet", urlPatterns = {"/ProductoServlet"})
public class ProductoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("vendedor") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String accion = request.getParameter("accion");
        ProductoDAO productoDAO = new ProductoDAO();
        CategoriaDAO categoriaDAO = new CategoriaDAO();

        // 🔥 NUEVA ACCIÓN: Cargar producto para editar
        if ("editar".equals(accion)) {
            String idStr = request.getParameter("id");
            if (idStr != null && !idStr.trim().isEmpty()) {
                try {
                    int id = Integer.parseInt(idStr.trim());
                    Producto productoEditar = productoDAO.buscarPorId(id);
                    request.setAttribute("productoEditar", productoEditar);
                } catch (NumberFormatException e) {
                    request.setAttribute("mensaje", "ID inválido.");
                }
            }
        }
        else if ("eliminar".equals(accion)) {
            String idStr = request.getParameter("id");
            if (idStr != null && !idStr.trim().isEmpty()) {
                try {
                    int id = Integer.parseInt(idStr.trim());
                    boolean ok = productoDAO.eliminar(id);
                    request.setAttribute("mensaje", ok ? "Producto eliminado correctamente." : "Error al eliminar producto.");
                } catch (NumberFormatException e) {
                    request.setAttribute("mensaje", "ID inválido.");
                }
            }
        }

        // Filtros
        String q              = request.getParameter("q");
        String catStr         = request.getParameter("categoria");
        String minStr         = request.getParameter("precioMin");
        String maxStr         = request.getParameter("precioMax");
        String soloStr        = request.getParameter("soloDisponibles");
        String orden          = request.getParameter("orden");
        String filtroResenas  = request.getParameter("resenas");

        Integer categoriaId = null;
        Double precioMin = null, precioMax = null;
        boolean soloDisponibles = "on".equals(soloStr) || "true".equals(soloStr);

        try { if (catStr != null && !catStr.isBlank()) categoriaId = Integer.parseInt(catStr); } catch (NumberFormatException ignored) {}
        try { if (minStr != null && !minStr.isBlank()) precioMin = Double.parseDouble(minStr); } catch (NumberFormatException ignored) {}
        try { if (maxStr != null && !maxStr.isBlank()) precioMax = Double.parseDouble(maxStr); } catch (NumberFormatException ignored) {}

        boolean hayFiltros = (q != null && !q.isBlank()) ||
                             categoriaId != null ||
                             precioMin != null || precioMax != null ||
                             soloDisponibles ||
                             (orden != null && !orden.isBlank()) ||
                             (filtroResenas != null && !filtroResenas.isBlank() && !"todas".equals(filtroResenas));

        java.util.List<Producto> productos;
        if (hayFiltros) {
            productos = productoDAO.buscarConFiltros(q, categoriaId, precioMin, precioMax,
                                                      soloDisponibles, orden, filtroResenas);
        } else {
            productos = productoDAO.listar();
        }

        request.setAttribute("productos", productos);
        request.setAttribute("categorias", categoriaDAO.listar());

        request.setAttribute("filtroQ", q);
        request.setAttribute("filtroCategoria", catStr);
        request.setAttribute("filtroPrecioMin", minStr);
        request.setAttribute("filtroPrecioMax", maxStr);
        request.setAttribute("filtroSoloDisponibles", soloDisponibles);
        request.setAttribute("filtroOrden", orden);
        request.setAttribute("filtroResenas", filtroResenas);

        request.getRequestDispatcher("productos.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("vendedor") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String accion = request.getParameter("accion");

        if ("actualizarStock".equals(accion)) {
            try {
                String productIdStr  = request.getParameter("productId");
                String nuevoStockStr = request.getParameter("nuevoStock");

                if (productIdStr == null || nuevoStockStr == null ||
                    productIdStr.trim().isEmpty() || nuevoStockStr.trim().isEmpty()) {
                    request.setAttribute("mensaje", "⚠️ Debes indicar el ID y el nuevo stock.");
                } else {
                    int productId = Integer.parseInt(productIdStr.trim());
                    int nuevoStock = Integer.parseInt(nuevoStockStr.trim());

                    if (nuevoStock < 0) {
                        request.setAttribute("mensaje", "⚠️ El stock no puede ser negativo.");
                    } else {
                        ProductoDAO dao = new ProductoDAO();
                        boolean ok = dao.actualizarStock(productId, nuevoStock);
                        request.setAttribute("mensaje", ok
                            ? "✅ Stock actualizado correctamente a " + nuevoStock + " unidades."
                            : "❌ Error al actualizar el stock.");
                    }
                }
            } catch (NumberFormatException e) {
                request.setAttribute("mensaje", "⚠️ El stock debe ser un número entero válido.");
            } catch (Exception e) {
                request.setAttribute("mensaje", "Error: " + e.getMessage());
            }
        }
        // 🔥 NUEVA ACCIÓN: Guardar los cambios del formulario de edición
        else if ("guardarEdicion".equals(accion)) {
            try {
                int id = Integer.parseInt(request.getParameter("productId"));
                String nombre = request.getParameter("nombre");
                double precio = Double.parseDouble(request.getParameter("precio"));
                int categoriaId = Integer.parseInt(request.getParameter("categoriaId"));

                ProductoDAO dao = new ProductoDAO();
                boolean ok = dao.actualizarProducto(id, nombre.trim(), precio, categoriaId);
                
                request.setAttribute("mensaje", ok 
                    ? "✅ Producto actualizado correctamente." 
                    : "❌ Error al actualizar el producto.");
            } catch (Exception e) {
                request.setAttribute("mensaje", "Error al guardar edición: " + e.getMessage());
            }
        }
        else if ("agregarCategoria".equals(accion)) {
            try {
                String nombreCat = request.getParameter("nombreCategoria");
                String descCat   = request.getParameter("descripcionCategoria");
                if (nombreCat == null || nombreCat.trim().isEmpty()) {
                    request.setAttribute("mensaje", "⚠️ El nombre de la categoría es obligatorio.");
                } else {
                    CategoriaDAO dao = new CategoriaDAO();
                    boolean ok = dao.insertar(nombreCat.trim(), descCat != null ? descCat.trim() : "");
                    request.setAttribute("mensaje", ok ? "✅ Categoría agregada correctamente." : "❌ Error al agregar categoría.");
                }
            } catch (Exception e) {
                request.setAttribute("mensaje", "Error: " + e.getMessage());
            }
        }
        else if ("agregar".equals(accion) || accion == null) {
            try {
                String nombre      = request.getParameter("nombre");
                String cantidadStr = request.getParameter("cantidad");
                String precioStr   = request.getParameter("precio");
                String categoria   = request.getParameter("categoria");

                if (nombre == null || nombre.trim().isEmpty() ||
                    cantidadStr == null || cantidadStr.trim().isEmpty() ||
                    precioStr == null || precioStr.trim().isEmpty()) {
                    request.setAttribute("mensaje", "⚠️ Todos los campos son obligatorios.");
                    doGet(request, response);
                    return;
                }

                int cantidad = Integer.parseInt(cantidadStr.trim());
                double precio = Double.parseDouble(precioStr.trim());

                ProductoDAO dao = new ProductoDAO();
                boolean ok = dao.insertar(nombre.trim(), cantidad, precio, categoria);
                request.setAttribute("mensaje", ok ? "Producto agregado correctamente." : "Error al agregar producto.");

            } catch (NumberFormatException e) {
                request.setAttribute("mensaje", "⚠️ Verifica que cantidad y precio sean números válidos.");
            } catch (Exception e) {
                request.setAttribute("mensaje", "Error: " + e.getMessage());
            }
        }
        else {
            request.setAttribute("mensaje", "Acción no reconocida: " + accion);
        }

        doGet(request, response);
    }
}