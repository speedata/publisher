// =============================================================================
// Sidebar Navigation — Collapsible sections
// =============================================================================

document.addEventListener('DOMContentLoaded', function () {
  // Collapsible sections — nur der Pfeil-Button toggelt, der Link navigiert normal
  document.querySelectorAll('.nav-section-toggle').forEach(function (btn) {
    btn.addEventListener('click', function () {
      const section = btn.closest('.nav-section');
      section.classList.toggle('open');
    });
  });

  // Auto-open sections containing the active link
  const activeLink = document.querySelector('#sidebar-nav a.active');
  if (activeLink) {
    let el = activeLink.parentElement;
    while (el && el.id !== 'sidebar-nav') {
      if (el.classList.contains('nav-section')) {
        el.classList.add('open');
      }
      el = el.parentElement;
    }
  }

  // =============================================================================
  // Mobile sidebar toggle
  // =============================================================================

  const hamburger = document.getElementById('hamburger');
  const sidebar = document.getElementById('sidebar');
  if (hamburger && sidebar) {
    hamburger.addEventListener('click', function () {
      sidebar.classList.toggle('open');
    });
    // Close sidebar when clicking outside
    document.addEventListener('click', function (e) {
      if (sidebar.classList.contains('open') &&
          !sidebar.contains(e.target) &&
          !hamburger.contains(e.target)) {
        sidebar.classList.remove('open');
      }
    });
  }

  // =============================================================================
  // Code Copy Button
  // =============================================================================

  const isDE = document.documentElement.lang === 'de';
  const copyLabel = isDE ? 'Kopieren' : 'Copy';
  const copiedLabel = isDE ? 'Kopiert!' : 'Copied!';

  document.querySelectorAll('pre').forEach(function (pre) {
    const wrapper = document.createElement('div');
    wrapper.className = 'code-copy-container';
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    const btn = document.createElement('button');
    btn.className = 'code-copy-btn';
    btn.textContent = copyLabel;
    wrapper.appendChild(btn);

    btn.addEventListener('click', function () {
      const code = pre.querySelector('code') || pre;
      navigator.clipboard.writeText(code.innerText).then(function () {
        btn.textContent = copiedLabel;
        btn.classList.add('copied');
        setTimeout(function () {
          btn.textContent = copyLabel;
          btn.classList.remove('copied');
        }, 2000);
      });
    });
  });

  // =============================================================================
  // TOC scroll highlighting
  // =============================================================================

  const tocLinks = document.querySelectorAll('#toc-container a');
  if (tocLinks.length > 0) {
    // Spans mit id innerhalb von Headings (unsere render-heading Struktur)
    const headingSpans = Array.from(
      document.querySelectorAll('#content h2 span[id], #content h3 span[id], #content h4 span[id]')
    );

    function updateTocActive() {
      const scrollY = window.scrollY + 100;
      let currentId = null;
      headingSpans.forEach(function (span) {
        if (span.parentElement.offsetTop <= scrollY) currentId = span.id;
      });
      tocLinks.forEach(function (link) {
        link.classList.remove('active');
        if (currentId && link.getAttribute('href') === '#' + currentId) {
          link.classList.add('active');
        }
      });
    }

    window.addEventListener('scroll', updateTocActive, { passive: true });
    updateTocActive();
  }
});
