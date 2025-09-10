user_data = base64encode(<<-EOF
  #!/bin/bash
  set -euxo pipefail

  # Determine package manager (yum for Amazon Linux 2, dnf for AL2023)
  if command -v dnf &>/dev/null; then PM=dnf; else PM=yum; fi

  # Install Apache HTTP Server
  ${PM} -y update
  ${PM} -y install httpd

  # Enable and start the web server
  systemctl enable httpd
  systemctl start httpd

  # Get IMDSv2 token (silently ignore failures)
  TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)

  # Helper to query metadata with the token
  md() { curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/$1" || true; }

  PUBLIC_IP="$(md public-ipv4)"
  PRIVATE_IP="$(md local-ipv4)"

  # Choose an origin for YouTube embeds
  if [ -n "${PUBLIC_IP}" ]; then
    ORIGIN="http://${PUBLIC_IP}"
  elif [ -n "${PRIVATE_IP}" ]; then
    ORIGIN="http://${PRIVATE_IP}"
  else
    ORIGIN="http://localhost"
  fi

  # ----- Write the CSS file -----
  cat > /var/www/html/styles.css <<'CSS'
  /* ========== Theme tokens ========== */
  :root{
    --bg-1: #070a12;
    --ink: #eaf0ff;
    --muted: #b7c0d8;
    --accent: 255 95 120;
    --card: rgba(255,255,255,0.07);
    --stroke: rgba(255,255,255,0.10);
    --shadow-1: 0 18px 40px rgba(0,0,0,.55);
    --shadow-2: 0 30px 80px rgba(0,0,0,.65);
  }

  *{ box-sizing:border-box; margin:0; padding:0; }
  html, body{ height:100%; }
  body{
    background: var(--bg-1);
    color: var(--ink);
    font-family: Inter, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, "Apple Color Emoji","Segoe UI Emoji";
    line-height: 1.6;
    overflow-x: hidden;
  }

  .cosmos{
    position: fixed; inset: 0; z-index: -3;
    background:
      radial-gradient(60% 80% at 20% 10%, rgba(80, 125, 255,.18), transparent 55%),
      radial-gradient(70% 70% at 80% 80%, rgba(255,92,154,.18), transparent 60%),
      url("https://images.unsplash.com/photo-1444703686981-a3abbc4d4fe3?auto=format&fit=crop&w=2400&q=60") center/cover no-repeat;
    opacity:.22; filter:saturate(1.1) blur(1px);
  }

  .stars{
    position: fixed; inset: 0; z-index: -2; pointer-events:none;
    background:
      radial-gradient(2px 2px at 20% 30%, #fff8 30%, transparent 31%) repeat,
      radial-gradient(1.5px 1.5px at 70% 60%, #fff7 30%, transparent 31%) repeat,
      radial-gradient(1.2px 1.2px at 40% 80%, #fff5 30%, transparent 31%) repeat;
    background-size: 500px 350px, 420px 300px, 380px 260px;
    opacity:.4;
  }

  .nebula{
    position: fixed; inset: -10%; z-index:-1; filter:blur(60px);
    background:
      radial-gradient(600px 400px at 15% 70%, rgba(58,170,255,.20), transparent 60%),
      radial-gradient(700px 500px at 85% 25%, rgba(255,105,180,.18), transparent 60%),
      radial-gradient(500px 500px at 50% 40%, rgba(143,255,202,.12), transparent 65%);
    opacity:.35;
  }

  .page-header{
    text-align:center;
    padding:clamp(24px,6vw,56px) 16px 8px;
  }
  .manga-title{
    font-family: "Bangers", cursive;
    font-size:clamp(40px,7vw,88px);
    letter-spacing:1px;
    transform:skewX(-2deg);
    text-shadow:
      0 3px 0 rgba(0,0,0,.3),
      0 8px 18px rgba(0,0,0,.45),
      0 0 24px rgba(var(--accent)/.35);
    -webkit-text-stroke:1.5px rgba(255,255,255,.15);
  }
  .manga-title .burst{
    background: linear-gradient(135deg, rgba(var(--accent)/.95), rgba(255,180,70,.95));
    -webkit-background-clip: text; background-clip: text;
    color: transparent;
    text-shadow: 0 0 20px rgba(255,120,120,.35);
    margin-right:.25ch;
  }
  .subheading{
    color: var(--muted);
    max-width:78ch;
    margin:12px auto 0;
  }

  .fight-list{
    display:flex;
    flex-wrap:wrap;
    gap:clamp(16px,2.5vw,28px);
    padding:clamp(16px,3vw,36px);
    justify-content:center;
  }
  .fight-card{
    position:relative;
    flex:1 1 360px;
    max-width:520px;
    background:linear-gradient(180deg,rgba(255,255,255,.07),rgba(255,255,255,.04));
    border:1px solid var(--stroke);
    border-radius:18px;
    padding:16px 16px 20px;
    box-shadow:0 8px 24px rgba(0,0,0,.35);
    backdrop-filter:blur(8px);
    transition:transform .22s ease, box-shadow .22s ease, border-color .22s ease;
  }
  .fight-card:hover{
    transform: translateY(-4px);
    box-shadow: 0 18px 44px rgba(0,0,0,.55), 0 0 0 1px rgba(var(--accent)/.25);
    border-color: rgba(var(--accent)/.35);
  }
  .rank{
    position:absolute; top:-12px; left:-12px;
    background: rgba(var(--accent)/.95);
    color:#fff; padding:8px 12px;
    border-radius:999px;
    font-weight:800;
    letter-spacing:.6px;
    box-shadow:0 8px 22px rgba(255,95,120,.35);
  }
  .fight-title{
    font-family:"Bangers", cursive;
    font-size:clamp(20px,2.2vw,28px);
    letter-spacing:.5px;
    margin:8px 6px 12px;
    text-shadow:0 3px 0 rgba(0,0,0,.35), 0 10px 20px rgba(0,0,0,.4);
  }
  .fight-title .series{
    display:block;
    font-family:Inter,system-ui,sans-serif;
    font-weight:500;
    color:var(--muted);
    letter-spacing:.2px;
    margin-top:2px;
  }
  .video-container{
    position:relative;
    width:100%;
    aspect-ratio:16/9;
    border-radius:14px;
    overflow:hidden;
    border:1px solid var(--stroke);
    background:#070a12;
    box-shadow: var(--shadow-1), inset 0 0 60px rgba(255,255,255,.03);
    transition:box-shadow .22s ease, transform .22s ease;
  }
  .fight-card:hover .video-container{
    box-shadow: var(--shadow-2), inset 0 0 80px rgba(255,255,255,.04);
    transform:translateY(-1px);
  }
  .video-container iframe{
    position:absolute; inset:0;
    width:100%; height:100%;
    border:0;
  }
  .page-footer{
    text-align:center;
    color:var(--muted);
    padding:18px;
  }
  @media (prefers-reduced-motion:reduce){
    .fight-card, .video-container { transition:none; }
  }
  CSS

  # ----- Write the HTML file -----
  cat > /var/www/html/index.html <<HTML
  <!doctype html>
  <html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
    <!-- Emoji favicon -->
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🌌</text></svg>">
    <title>Top 10 Anime Fight Scenes</title>
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Bangers&family=Inter:wght@300;500;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="styles.css" />
  </head>
  <body>
    <div class="cosmos" aria-hidden="true"></div>
    <div class="stars" aria-hidden="true"></div>
    <div class="nebula" aria-hidden="true"></div>

    <header class="page-header">
      <h1 class="manga-title"><span class="burst">Top 10</span> Anime Fight Scenes</h1>
      <p class="subheading">Relive the most intense showdowns in anime history — now with a cosmic glow.</p>
    </header>

    <main class="fight-list">
      <section class="fight-card">
        <span class="rank">#1</span>
        <h2 class="fight-title">Wing Zero vs Epyon <span class="series">Mobile Suit Gundam Wing</span></h2>
        <div class="video-container">
          <iframe src="https://www.youtube-nocookie.com/embed/un4O_bv8510?rel=0&modestbranding=1&origin=${ORIGIN}"
            title="Wing Zero vs Epyon — Gundam Wing" loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </section>

      <!-- 2 -->
      <section class="fight-card">
        <span class="rank">#2</span>
        <h2 class="fight-title">Naruto vs Sasuke – Final Battle <span class="series">Naruto Shippuden</span></h2>
        <div class="video-container">
          <iframe src="https://www.youtube-nocookie.com/embed/qi2rByJed-E?rel=0&modestbranding=1&origin=${ORIGIN}"
            title="Naruto vs Sasuke Final Battle" loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </section>

      <!-- 3 -->
      <section class="fight-card">
        <span class="rank">#3</span>
        <h2 class="fight-title">Goku (Ultra Instinct) vs Jiren <span class="series">Dragon Ball Super</span></h2>
        <div class="video-container">
          <iframe src="https://www.youtube-nocookie.com/embed/ZJeZXJ4WsxQ?rel=0&modestbranding=1&origin=${ORIGIN}"
            title="Ultra Instinct Goku vs Jiren" loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </section>

      <!-- 4 -->
      <section class="fight-card">
        <span class="rank">#4</span>
        <h2 class="fight-title">Yuji Itadori & Aoi Todo vs Hanami <span class="series">Jujutsu Kaisen</span></h2>
        <div class="video-container">
          <iframe src="https://www.youtube-nocookie.com/embed/MhROyD9HbLE?rel=0&modestbranding=1&origin=${ORIGIN}"
            title="Boogie Woogie — Itadori & Todo vs Hanami" loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </section>

      <!-- 5 -->
      <section class="fight-card">
        <span class="rank">#5</span>
        <h2 class="fight-title">Gon vs Neferpitou <span class="series">Hunter x Hunter</span></h2>
        <div class="video-container">
          <iframe src="https://www.youtube-nocookie.com/embed/prWR7FXMUDM?rel=0&modestbranding=1&origin=${ORIGIN}"
            title="Gon vs Neferpitou" loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </section>

      <!-- 6 -->
      <section class="fight-card">
        <span class="rank">#6</span>
        <h2 class="fight-title">All Might vs All For One – United States of Smash <span class="series">My Hero Academia</span></h2>
        <div class="video-container">
          <iframe src="https://www.youtube-nocookie.com/embed/CDW2ReQZOQU?rel=0&modestbranding=1&origin=${ORIGIN}"
            title="United States of Smash" loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </section>

      <!-- 7 -->
      <section class="fight-card">
        <span class="rank">#7</span>
        <h2 class="fight-title">Luffy vs Rob Lucci <span class="series">One Piece</span></h2>
        <div class="video-container">
          <iframe src="https://www.youtube-nocookie.com/embed/Tpo32yP_Pho?rel=0&modestbranding=1&origin=${ORIGIN}"
            title="Luffy vs Rob Lucci" loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </section>

      <!-- 8 -->
      <section class="fight-card">
        <span class="rank">#8</span>
        <h2 class="fight-title">Tengen Uzui & Tanjiro vs Gyutaro & Daki <span class="series">Demon Slayer</span></h2>
        <div class="video-container">
          <iframe src="https://www.youtube-nocookie.com/embed/nCyr-QAxzUc?rel=0&modestbranding=1&origin=${ORIGIN}"
            title="Gyutaro/Daki vs Tengen/Tanjiro" loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </section>

      <!-- 9 -->
      <section class="fight-card">
        <span class="rank">#9</span>
        <h2 class="fight-title">Roy Mustang vs Envy <span class="series">Fullmetal Alchemist: Brotherhood</span></h2>
        <div class="video-container">
          <iframe src="https://www.youtube-nocookie.com/embed/Lp1mbWaBs70?rel=0&modestbranding=1&origin=${ORIGIN}"
            title="Roy Mustang vs Envy" loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </section>

      <!-- 10 -->
      <section class="fight-card">
        <span class="rank">#10</span>
        <h2 class="fight-title">Saitama vs Boros <span class="series">One-Punch Man</span></h2>
        <div class="video-container">
          <iframe src="https://www.youtube-nocookie.com/embed/ErXfj3sbIfU?rel=0&modestbranding=1&origin=${ORIGIN}"
            title="Saitama vs Boros" loading="lazy"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </section>
    </main>

    <footer class="page-footer">
      <p>&copy; <span id="year"></span> Anime Fights List.</p>
    </footer>

    <script>
      document.getElementById('year').textContent = new Date().getFullYear();
    </script>
  </body>
  </html>
  HTML

  # Fix ownership and permissions
  chown apache:apache /var/www/html/index.html /var/www/html/styles.css || true
  chmod 644 /var/www/html/index.html /var/www/html/styles.css

  echo "Anime fights page is ready at ${ORIGIN}"
EOF
