# Frequently Asked Questions (FAQ)

## 1. Routing and Access

### Q: Why is my new file not taking effect?
**A**: Ensure the file is located in the `src/pages/` or `src/api/` directory and has the `.ex` extension. In development mode, Nex automatically scans for new files, but if there's a compilation error, the route might not be registered. Please check the terminal output.

### Q: What if dynamic route `[id].ex` and static route `new.ex` conflict?
**A**: Nex prioritizes static paths. Visiting `/users/new` will match `new.ex`, while visiting `/users/123` will match `[id].ex`.

## 2. Interaction and Response

### Q: Why is my `hx-post` button click not responding?
**A**:
1.  Check the browser console for CSRF validation failure (403) errors.
2.  Ensure your Layout includes necessary interaction scripts (like HTMX).
3.  Ensure your defined Action function name matches the path name exactly (e.g., `hx-post="/add"` corresponds to `def add(_params)`).

### Q: The response returned, but the page didn't update?
**A**: Check if `hx-target` points to the correct ID. If the Action returns `:empty`, no DOM changes will occur on the page.

## 3. State Management (Nex.Store)

### Q: Why is my shopping cart empty after refreshing the page?
**A**: This is the design intent of **Nex.Store**. State is bound to the `page_id`, and a full page refresh generates a new ID. If you need persistent storage, please use a database.

### Q: Does `Nex.Store` cause memory overflow?
**A**: No. Nex has a built-in TTL (Time To Live) cleanup mechanism; state automatically expires after 1 hour by default. Additionally, a background process performs a full scan every 5 minutes.

## 4. Deployment and Environment

### Q: How do I set keys in production?
**A**: Set the environment variable `SECRET_KEY_BASE`. You can generate a sufficiently long random string using `mix phx.gen.secret`.

### Q: Is HTTPS supported?
**A**: Nex focuses on Web logic. In production, we recommend placing Nginx or Caddy in front of Nex to handle SSL/TLS certificates.
