package com.mercadeonica.controlador;

import com.mercadeonica.dao.ClienteDAO;
import com.mercadeonica.dao.VendedorDAO;
import com.mercadeonica.dao.ProductoDAO;
import com.mercadeonica.modelo.Cliente;
import com.mercadeonica.modelo.Vendedor;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet(name = "LoginUnificadoServlet", urlPatterns = {"/LoginUnificadoServlet"})
public class LoginUnificadoServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email    = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || email.isBlank() || password == null || password.isBlank()) {
            request.setAttribute("error", "Debes ingresar correo y contraseña.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
            return;
        }

        email = email.trim();

        // PASO 1: VENDEDOR / ADMIN
        try {
            VendedorDAO vDao = new VendedorDAO();
            Vendedor vendedor = vDao.login(email, password);

            if (vendedor != null) {
                HttpSession session = request.getSession();
                session.setAttribute("vendedor", vendedor);
                session.setAttribute("nombreUsuario", vendedor.getNombre());
                session.setAttribute("rolUsuario", vendedor.getRol());
                
                // 🔥 NOTIFICACIONES DE STOCK (SOLO PARA ADMIN Y VENDEDOR)
                ProductoDAO prodDao = new ProductoDAO();
                session.setAttribute("stockBajo", prodDao.contarProductosBajoStock(50));
                session.setAttribute("stockAgotado", prodDao.contarProductosAgotados());
                
                response.sendRedirect("menu.jsp");
                return;
            }
        } catch (Exception e) {
            System.err.println("⚠️ Error al validar vendedor: " + e.getMessage());
        }

        // PASO 2: CLIENTE
        try {
            ClienteDAO cDao = new ClienteDAO();
            Cliente cliente = cDao.login(email, password);

            if (cliente != null) {
                HttpSession session = request.getSession();
                session.setAttribute("cliente", cliente);
                session.setAttribute("clienteNombre", cliente.getNombre());
                session.setAttribute("clienteId", cliente.getCustomerId());

                if (cliente.isDebeCambiarPassword()) {
                    System.out.println("⚠️ Cliente debe cambiar contraseña: " + cliente.getNombre());
                    response.sendRedirect("cliente-cambiar-password.jsp");
                    return;
                }

                response.sendRedirect("cliente-menu.jsp");
                return;
            }
        } catch (Exception e) {
            System.err.println("⚠️ Error al validar cliente: " + e.getMessage());
        }

        request.setAttribute("error", "Correo o contraseña incorrectos.");
        request.getRequestDispatcher("login.jsp").forward(request, response);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("login.jsp");
    }
}