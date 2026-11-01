package com.mercadeonica.controlador;

import com.mercadeonica.dao.VendedorDAO;
import com.mercadeonica.modelo.Vendedor;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet(name = "VendedorServlet", urlPatterns = {"/VendedorServlet"})
public class VendedorServlet extends HttpServlet {

    private static final String PHONE_REGEX = "^[+]?[\\d\\s\\-()]{7,20}$";

    // 🔥 SEPARAR NOMBRE COMPLETO EN NOMBRE Y APELLIDO
    private String[] separarNombre(String nombreCompleto) {
        if (nombreCompleto == null || nombreCompleto.trim().isEmpty()) {
            return new String[]{"", ""};
        }
        String[] partes = nombreCompleto.trim().split("\\s+", 2);
        String nombre = partes[0];
        String apellido = partes.length > 1 ? partes[1] : "";
        return new String[]{nombre, apellido};
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== VendedorServlet.doGet ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("vendedor") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Vendedor admin = (Vendedor) session.getAttribute("vendedor");

        if (!admin.esAdmin()) {
            System.out.println("⚠️ Acceso denegado: " + admin.getNombre());
            request.setAttribute("error", "Solo administradores pueden gestionar vendedores.");
            request.getRequestDispatcher("menu.jsp").forward(request, response);
            return;
        }

        VendedorDAO dao = new VendedorDAO();
        String accion = request.getParameter("accion");

        System.out.println("Acción: " + accion);
        System.out.println("ID: " + request.getParameter("id"));

        // ---------- ELIMINAR VENDEDOR ----------
        if ("eliminar".equals(accion)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                if (id == admin.getSellerId()) {
                    request.setAttribute("mensaje", "⚠️ No puedes eliminarte a ti mismo.");
                } else {
                    boolean ok = dao.eliminar(id);
                    request.setAttribute("mensaje", ok
                        ? "Vendedor eliminado correctamente."
                        : "Error al eliminar vendedor.");
                }
            } catch (NumberFormatException e) {
                request.setAttribute("mensaje", "ID inválido.");
            }
        }
        // ---------- ACTIVAR/DESACTIVAR VENDEDOR ----------
        else if ("activar".equals(accion) || "desactivar".equals(accion)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                boolean activar = "activar".equals(accion);

                if (id == admin.getSellerId()) {
                    request.setAttribute("mensaje", "⚠️ No puedes cambiar tu propio estado.");
                } else {
                    boolean ok = dao.cambiarEstado(id, activar);
                    request.setAttribute("mensaje", ok
                        ? "Estado actualizado correctamente."
                        : "Error al cambiar estado.");
                }
            } catch (NumberFormatException e) {
                request.setAttribute("mensaje", "ID inválido.");
            }
        }
        // ---------- CARGAR FORMULARIO DE CAMBIO DE CONTRASEÑA ----------
        else if ("formPassword".equals(accion)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                System.out.println("🔐 Cargando formulario de password para ID: " + id);

                Vendedor vendedor = dao.buscarPorId(id);

                if (vendedor == null) {
                    request.setAttribute("mensaje", "Vendedor no encontrado.");
                    System.out.println("❌ Vendedor no encontrado");
                } else {
                    request.setAttribute("vendedorSeleccionado", vendedor);
                    System.out.println("✅ Vendedor cargado: " + vendedor.getNombre());
                }
            } catch (NumberFormatException e) {
                request.setAttribute("mensaje", "ID inválido.");
                System.err.println("❌ ID inválido: " + e.getMessage());
            }
        }
        // ---------- 🔥 CARGAR FORMULARIO DE EDICIÓN ----------
        else if ("editar".equals(accion)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                System.out.println("✏️ Cargando formulario de edición para ID: " + id);

                Vendedor vendedor = dao.buscarPorId(id);

                if (vendedor == null) {
                    request.setAttribute("mensaje", "Vendedor no encontrado.");
                    System.out.println("❌ Vendedor no encontrado");
                } else {
                    // 🔥 SEPARAR NOMBRE Y APELLIDO PARA EL FORMULARIO
                    String[] partes = separarNombre(vendedor.getNombre());
                    request.setAttribute("vendedorEditar", vendedor);
                    request.setAttribute("editNombre", partes[0]);
                    request.setAttribute("editApellido", partes[1]);
                    System.out.println("✅ Vendedor para editar: " + vendedor.getNombre());
                }
            } catch (NumberFormatException e) {
                request.setAttribute("mensaje", "ID inválido.");
                System.err.println("❌ ID inválido: " + e.getMessage());
            }
        }

        // Listar todos los vendedores
        request.setAttribute("vendedores", dao.listar());
        request.getRequestDispatcher("vendedores.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== VendedorServlet.doPost ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("vendedor") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Vendedor admin = (Vendedor) session.getAttribute("vendedor");

        if (!admin.esAdmin()) {
            response.sendRedirect("menu.jsp");
            return;
        }

        String accion = request.getParameter("accion");
        System.out.println("Acción POST: " + accion);

        // ---------- CAMBIAR CONTRASEÑA ----------
        if ("cambiarPassword".equals(accion)) {
            try {
                int sellerId = Integer.parseInt(request.getParameter("sellerId"));
                String passwordNueva = request.getParameter("passwordNueva");
                String passwordConfirm = request.getParameter("passwordConfirm");

                if (passwordNueva == null || passwordNueva.isEmpty()) {
                    request.setAttribute("mensaje", "⚠️ La nueva contraseña es obligatoria.");
                    doGet(request, response);
                    return;
                }

                if (passwordNueva.length() < 6) {
                    request.setAttribute("mensaje", "⚠️ La contraseña debe tener al menos 6 caracteres.");
                    doGet(request, response);
                    return;
                }

                if (!passwordNueva.equals(passwordConfirm)) {
                    request.setAttribute("mensaje", "⚠️ Las contraseñas no coinciden.");
                    doGet(request, response);
                    return;
                }

                VendedorDAO dao = new VendedorDAO();
                boolean ok = dao.cambiarPasswordAdmin(sellerId, passwordNueva);

                if (ok) {
                    request.setAttribute("mensaje", "✅ Contraseña actualizada correctamente.");
                    System.out.println("✅ Contraseña actualizada para vendedor ID: " + sellerId);
                } else {
                    request.setAttribute("mensaje", "❌ Error al actualizar la contraseña.");
                }

            } catch (Exception e) {
                System.err.println("❌ Error: " + e.getMessage());
                e.printStackTrace();
                request.setAttribute("mensaje", "Error: " + e.getMessage());
            }
        }
        // ---------- GUARDAR EDICIÓN (NOMBRE + APELLIDO) ----------
        else if ("guardarEdicion".equals(accion)) {
            try {
                int sellerId       = Integer.parseInt(request.getParameter("sellerId"));
                String nombre      = request.getParameter("nombre");
                String apellido    = request.getParameter("apellido");
                String email       = request.getParameter("email");
                String telefono    = request.getParameter("telefono");
                String rolOriginal = request.getParameter("rolOriginal");
                String rol         = request.getParameter("rol");

                if (telefono != null) telefono = telefono.trim();
                if (telefono != null && telefono.isEmpty()) telefono = null;

                if (nombre == null || nombre.trim().isEmpty() ||
                    apellido == null || apellido.trim().isEmpty() ||
                    email == null || email.trim().isEmpty() ||
                    rol == null || rol.trim().isEmpty()) {
                    request.setAttribute("mensaje", "⚠️ Nombre, apellido, email y rol son obligatorios.");
                    doGet(request, response);
                    return;
                }

                if (telefono != null && !telefono.matches(PHONE_REGEX)) {
                    request.setAttribute("mensaje", "⚠️ Teléfono inválido. Ej: +505 8888-8888");
                    doGet(request, response);
                    return;
                }

                if (sellerId == admin.getSellerId() && !rol.equals(rolOriginal)) {
                    request.setAttribute("mensaje",
                        "🔒 No puedes cambiar tu propio rol (evita bloquearte a ti mismo).");
                    doGet(request, response);
                    return;
                }

                // 🔥 CONCATENAR NOMBRE Y APELLIDO
                String nombreCompleto = nombre.trim() + " " + apellido.trim();

                VendedorDAO dao = new VendedorDAO();
                String error = dao.actualizar(sellerId, nombreCompleto, email.trim(), telefono, rol);

                if (error == null) {
                    request.setAttribute("mensaje", "✅ Vendedor actualizado correctamente.");
                    System.out.println("✅ Vendedor actualizado: ID " + sellerId);
                } else {
                    request.setAttribute("mensaje", "⚠️ " + error);
                }

            } catch (NumberFormatException e) {
                request.setAttribute("mensaje", "⚠️ Datos inválidos: " + e.getMessage());
            } catch (Exception e) {
                System.err.println("❌ Error: " + e.getMessage());
                e.printStackTrace();
                request.setAttribute("mensaje", "Error: " + e.getMessage());
            }
        }
        // ---------- AGREGAR VENDEDOR (NOMBRE + APELLIDO) ----------
        else {
            try {
                String nombre   = request.getParameter("nombre");
                String apellido = request.getParameter("apellido");
                String email    = request.getParameter("email");
                String telefono = request.getParameter("telefono");
                String password = request.getParameter("password");
                String rol      = request.getParameter("rol");

                if (telefono != null) telefono = telefono.trim();
                if (telefono != null && telefono.isEmpty()) telefono = null;

                if (nombre == null || nombre.trim().isEmpty() ||
                    apellido == null || apellido.trim().isEmpty()) {
                    request.setAttribute("mensaje", "⚠️ Nombre y apellido son obligatorios.");
                    doGet(request, response);
                    return;
                }

                // 🔥 CONCATENAR NOMBRE Y APELLIDO
                String nombreCompleto = nombre.trim() + " " + apellido.trim();

                System.out.println("📥 Agregando vendedor: " + nombreCompleto);

                VendedorDAO dao = new VendedorDAO();
                boolean ok = dao.insertar(nombreCompleto, email, telefono, password, rol);

                request.setAttribute("mensaje", ok
                    ? "Vendedor agregado correctamente."
                    : "Error al agregar vendedor. Verifica que el email no esté duplicado.");

            } catch (Exception e) {
                System.err.println("❌ Error: " + e.getMessage());
                request.setAttribute("mensaje", "Error: " + e.getMessage());
            }
        }

        doGet(request, response);
    }
}