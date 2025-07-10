# ZIMCHE Audit Backend - Thymeleaf UI Integration

## Overview
This integration adds a modern, responsive web interface to your existing ZIMCHE Audit Backend API using Thymeleaf templates with an orange corporate theme.

## What's Included

### 🎨 UI Components
- **Modern Orange Theme**: Corporate design with orange (#FF6B35) as primary color
- **Responsive Layout**: Mobile-first design that works on all devices
- **Authentication UI**: Login/logout with Spring Security integration
- **Dashboard**: Statistics overview and activity feed
- **University Management**: List, view, and manage universities
- **Document Management**: Upload, view, and organize audit documents
- **User Profile**: View and edit user information
- **Admin Panel**: Administrative functions for system management

### 🛠️ Technical Features
- **Dual Interface**: Your API endpoints remain unchanged - both REST API and web UI work together
- **Security Integration**: Uses existing Spring Security with form-based login for web UI
- **Role-Based Access**: Content shows/hides based on user roles (ADMIN, USER)
- **Mobile Responsive**: Collapsible sidebar, touch-friendly interface
- **Modern Animations**: Smooth transitions and hover effects
- **File Upload**: Drag-and-drop file upload with progress indicators

### 📁 File Structure Added
```
src/main/resources/
├── templates/
│   ├── layout/           # Base layout templates
│   ├── fragments/        # Reusable components
│   ├── pages/           # Page templates
│   └── error/           # Error pages
└── static/
    ├── css/main.css     # Orange theme styles
    ├── js/main.js       # Interactive functionality
    └── images/          # UI assets
```

## Routes Added

### Web Routes (Thymeleaf)
- `/` - Landing page (redirects to dashboard if authenticated)
- `/login` - Login page
- `/dashboard` - Main dashboard
- `/universities` - Universities list and management
- `/documents` - Document management
- `/profile` - User profile
- `/admin` - Admin panel (ADMIN role only)

### API Routes (Unchanged)
- `/api/**` - All your existing REST API endpoints remain unchanged

## Usage

### For End Users
1. Visit `http://localhost:8080` for the web interface
2. Use existing credentials to log in
3. Navigate using the sidebar menu
4. Upload documents, view universities, manage audits

### For Developers
1. API endpoints at `/api/**` work exactly as before
2. Web interface uses the same backend services
3. Add new pages by creating Thymeleaf templates in `src/main/resources/templates/pages/`
4. Customize styling in `src/main/resources/static/css/main.css`

## Customization

### Colors
Edit CSS variables in `main.css`:
```css
:root {
    --primary-orange: #FF6B35;    /* Main brand color */
    --secondary-orange: #FF8C65;  /* Lighter variant */
    --dark-orange: #E55A2B;       /* Darker variant */
}
```

### Layout
- Modify `src/main/resources/templates/layout/base.html` for overall structure
- Edit `src/main/resources/templates/layout/sidebar.html` for navigation
- Update `src/main/resources/templates/layout/header.html` for top bar

### Add New Pages
1. Create template in `src/main/resources/templates/pages/yourpage.html`
2. Add route in `WebController.kt`
3. Add navigation link in sidebar template

## Browser Support
- Chrome 80+
- Firefox 75+
- Safari 13+
- Edge 80+

## Dependencies Added
- `spring-boot-starter-thymeleaf`
- `thymeleaf-extras-springsecurity6`

Your existing API functionality remains completely unchanged!
