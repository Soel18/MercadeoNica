package com.mercadeonica.controlador;

import com.mercadeonica.dao.CategoriaClienteDAO;
import com.mercadeonica.dao.ClienteDAO;
import com.mercadeonica.modelo.Cliente;
import com.mercadeonica.modelo.Vendedor;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet(name = "ClienteServlet", urlPatterns = {"/ClienteServlet"})
public class ClienteServlet extends HttpServlet {

    private static final String PHONE_REGEX = "^\\+505[\\s\\-]?[0-9\\s\\-]{8,15}$";

    private String formatearTitulo(String texto) {
        if (texto == null || texto.trim().isEmpty()) return texto;
        String[] palabras = texto.trim().toLowerCase().split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (String palabra : palabras) {
            if (palabra.length() > 0) {
                sb.append(Character.toUpperCase(palabra.charAt(0)))
                  .append(palabra.substring(1))
                  .append(" ");
            }
        }
        return sb.toString().trim();
    }

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

        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("vendedor") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Vendedor v = (Vendedor) session.getAttribute("vendedor");
        String accion = request.getParameter("accion");
        ClienteDAO clienteDAO = new ClienteDAO();
        CategoriaClienteDAO categoriaDAO = new CategoriaClienteDAO();

        String filtroQ = request.getParameter("q");
        if (filtroQ == null) filtroQ = "";

        if ("eliminar".equals(accion)) {
            if (v.esAdmin()) {
                try {
                    int id = Integer.parseInt(request.getParameter("id"));
                    boolean ok = clienteDAO.eliminar(id);
                    request.setAttribute("mensaje", ok 
                        ? "✅ Cliente desactivado correctamente. Su historial de compras se mantiene seguro." 
                        : "❌ Error al desactivar el cliente.");
                } catch (NumberFormatException e) {
                    request.setAttribute("mensaje", "ID inválido.");
                }
            } else {
                request.setAttribute("mensaje", "⚠️ Solo administradores pueden desactivar clientes.");
            }
        }
        else if ("cambiarCategoria".equals(accion)) {
            try {
                int customerId = Integer.parseInt(request.getParameter("customerId"));
                int categoryId = Integer.parseInt(request.getParameter("categoryId"));
                boolean ok = clienteDAO.cambiarCategoria(customerId, categoryId);
                request.setAttribute("mensaje", ok ? "✅ Categoría actualizada." : "❌ Error al cambiar categoría.");
            } catch (NumberFormatException e) {
                request.setAttribute("mensaje", "ID inválido.");
            }
        }
        else if ("editar".equals(accion)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Cliente clienteEditar = clienteDAO.buscarPorId(id);
                if (clienteEditar == null) {
                    request.setAttribute("mensaje", "❌ Cliente no encontrado (ID " + id + ").");
                } else {
                    // 🔥 SEPARAR NOMBRE Y APELLIDO PARA EL FORMULARIO
                    String[] partes = separarNombre(clienteEditar.getNombre());
                    request.setAttribute("clienteEditar", clienteEditar);
                    request.setAttribute("editNombre", partes[0]);
                    request.setAttribute("editApellido", partes[1]);
                }
            } catch (NumberFormatException e) {
                request.setAttribute("mensaje", "ID inválido.");
            }
        }

        List<Cliente> listaClientes;
        if (filtroQ.trim().isEmpty()) {
            listaClientes = clienteDAO.listar();
        } else {
            listaClientes = clienteDAO.buscarConFiltro(filtroQ.trim());
        }

        request.setAttribute("clientes", listaClientes);
        request.setAttribute("filtroQ", filtroQ);
        request.setAttribute("categoriasCliente", categoriaDAO.listar());
        request.getRequestDispatcher("clientes.jsp").forward(request, response);
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

        // 🔥 GUARDAR EDICIÓN (NOMBRE + APELLIDO SEPARADOS)
        if ("guardarEdicion".equals(accion)) {
            try {
                int customerId    = Integer.parseInt(request.getParameter("customerId"));
                String nombre     = formatearTitulo(request.getParameter("nombre"));
                String apellido   = formatearTitulo(request.getParameter("apellido"));
                String email      = request.getParameter("email");
                String telefono   = request.getParameter("telefono");
                String ciudad     = formatearTitulo(request.getParameter("ciudad"));
                String estado     = formatearTitulo(request.getParameter("estado"));
                int zip           = Integer.parseInt(request.getParameter("zip"));

                if (telefono != null) telefono = telefono.trim();
                if (telefono != null && telefono.isEmpty()) telefono = null;

                if (telefono != null && !telefono.matches(PHONE_REGEX)) {
                    request.setAttribute("mensaje", "⚠️ Teléfono inválido. Debe empezar con +505. Ej: +505 8888-8888");
                    request.setAttribute("error_field", "telefono");
                    doGet(request, response);
                    return;
                }

                String nombreCompleto = nombre + " " + apellido;

                ClienteDAO dao = new ClienteDAO();
                boolean ok = dao.actualizar(customerId, nombreCompleto, email.trim(), telefono, ciudad, estado, zip);

                request.setAttribute("mensaje", ok ? "✅ Cliente actualizado correctamente." : "❌ No se pudo actualizar.");

            } catch (IllegalArgumentException e) {
                request.setAttribute("mensaje", "⚠️ " + e.getMessage());
            } catch (Exception e) {
                request.setAttribute("mensaje", "Error: " + e.getMessage());
            }
            doGet(request, response);
            return;
        }

        try {
            String nombre     = formatearTitulo(request.getParameter("nombre"));
            String apellido   = formatearTitulo(request.getParameter("apellido"));
            String email      = request.getParameter("email");
            String ciudad     = formatearTitulo(request.getParameter("ciudad"));
            String estado     = formatearTitulo(request.getAttribute("estado") != null ? (String)request.getAttribute("estado") : request.getParameter("estado"));
            String zipStr     = request.getParameter("zip");
            String telefono   = request.getParameter("telefono");
            String password   = request.getParameter("password"); 
            String tarjetaStr = request.getParameter("tarjeta");
            String tipo       = request.getParameter("tipo");
            String mesStr     = request.getParameter("mes");
            String anioStr    = request.getParameter("anio");

            if (telefono != null) telefono = telefono.trim();
            if (telefono != null && telefono.isEmpty()) telefono = null;

            // 🔥 GUARDAR DATOS DEL FORMULARIO EN EL REQUEST PARA MANTENERLOS SI HAY ERROR
            request.setAttribute("reg_nombre", nombre);
            request.setAttribute("reg_apellido", apellido);
            request.setAttribute("reg_email", email);
            request.setAttribute("reg_ciudad", ciudad);
            request.setAttribute("reg_estado", estado);
            request.setAttribute("reg_zip", zipStr);
            request.setAttribute("reg_telefono", telefono);
            request.setAttribute("reg_password", password);
            request.setAttribute("reg_tarjeta", tarjetaStr);
            request.setAttribute("reg_tipo", tipo);
            request.setAttribute("reg_mes", mesStr);
            request.setAttribute("reg_anio", anioStr);

            if (nombre == null || nombre.trim().isEmpty() || 
                apellido == null || apellido.trim().isEmpty() ||
                email == null || email.trim().isEmpty() ||
                ciudad == null || ciudad.trim().isEmpty() || estado == null || estado.trim().isEmpty() ||
                zipStr == null || zipStr.trim().isEmpty() || password == null || password.trim().isEmpty()) {

                request.setAttribute("mensaje", "⚠️ Todos los campos del cliente son obligatorios (excepto teléfono y tarjeta).");
                request.setAttribute("error_field", "error_general");
                doGet(request, response);
                return;
            }

            if (telefono != null && !telefono.matches(PHONE_REGEX)) {
                request.setAttribute("mensaje", "⚠️ El teléfono debe empezar con +505. Ej: +505 8888-8888");
                request.setAttribute("error_field", "telefono");
                doGet(request, response);
                return;
            }

            ClienteDAO dao = new ClienteDAO();
            
            if (dao.buscarPorEmail(email.trim()) != null) {
                request.setAttribute("mensaje", "⚠️ El correo electrónico ya está registrado. Por favor, ingresa otro.");
                request.setAttribute("error_field", "email");
                doGet(request, response);
                return;
            }

            boolean tarjetaOpcional = (tarjetaStr == null || tarjetaStr.trim().isEmpty());
            if (!tarjetaOpcional && tarjetaStr.trim().length() != 16) {
                request.setAttribute("mensaje", "⚠️ El número de tarjeta debe tener exactamente 16 dígitos.");
                request.setAttribute("error_field", "tarjeta");
                doGet(request, response);
                return;
            }

            int zip = Integer.parseInt(zipStr.trim());
            long tarjeta = 0;
            int mes = 0;
            int anio = 0;

            if (!tarjetaOpcional) {
                tarjeta = Long.parseLong(tarjetaStr.trim());
                mes = Integer.parseInt(mesStr.trim());
                anio = Integer.parseInt(anioStr.trim());
                if (dao.tarjetaExiste(tarjeta)) {
                    request.setAttribute("mensaje", "⚠️ El número de tarjeta ya está registrado.");
                    request.setAttribute("error_field", "tarjeta");
                    doGet(request, response);
                    return;
                }
            }

            // 🔥 CONCATENAR NOMBRE Y APELLIDO
            String nombreCompleto = nombre + " " + apellido;

            boolean ok = dao.insertar(nombreCompleto, email.trim(), ciudad, estado,
                                      zip, telefono, password.trim(), 
                                      tarjetaOpcional ? null : tarjeta, 
                                      tarjetaOpcional ? null : tipo, 
                                      tarjetaOpcional ? 0 : mes, 
                                      tarjetaOpcional ? 0 : anio);

            if (ok) {
                request.setAttribute("mensaje", "✅ Cliente agregado correctamente.");
                request.removeAttribute("reg_nombre");
                request.removeAttribute("reg_apellido");
                request.removeAttribute("reg_email");
                request.removeAttribute("reg_ciudad");
                request.removeAttribute("reg_estado");
                request.removeAttribute("reg_zip");
                request.removeAttribute("reg_telefono");
                request.removeAttribute("reg_password");
                request.removeAttribute("reg_tarjeta");
                request.removeAttribute("reg_tipo");
                request.removeAttribute("reg_mes");
                request.removeAttribute("reg_anio");
            } else {
                request.setAttribute("mensaje", "❌ Error al agregar cliente.");
                request.setAttribute("error_field", "error_general");
            }

        } catch (NumberFormatException e) {
            request.setAttribute("mensaje", "⚠️ Error: Verifica que el ZIP, mes y año sean números válidos.");
            request.setAttribute("error_field", "error_general");
        } catch (SQLException e) { 
            System.err.println("❌ ERROR SQL AL AGREGAR CLIENTE: " + e.getMessage());
            request.setAttribute("mensaje", "❌ Error de BD: " + e.getMessage());
            request.setAttribute("error_field", "error_general");
        } catch (Exception e) {
            System.err.println("❌ ERROR GENERAL AL AGREGAR CLIENTE: " + e.getMessage());
            e.printStackTrace();
            request.setAttribute("mensaje", "Error general: " + e.getMessage());
            request.setAttribute("error_field", "error_general");
        }

        doGet(request, response);
    }
}