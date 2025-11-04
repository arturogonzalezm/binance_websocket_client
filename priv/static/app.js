(() => {
  const $ = (id) => document.getElementById(id);
  const fmt = new Intl.NumberFormat(undefined, { maximumFractionDigits: 2 });
  const fmt4 = new Intl.NumberFormat(undefined, { maximumFractionDigits: 4 });
  const fmtPerc = new Intl.NumberFormat(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
  const timeFmt = new Intl.DateTimeFormat(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit' });

  // UI elements
  const el = {
    status: $('connStatus'), price: $('price'), priceTime: $('priceTime'), change: $('change'), changeAbs: $('changeAbs'),
    high: $('high'), low: $('low'), vol: $('vol'), quoteVol: $('quoteVol'), feed: $('feed'),
    pauseBtn: $('pauseBtn'), clearBtn: $('clearBtn')
  };

  // Phoenix socket
  const socket = new window.Phoenix.Socket(`${location.protocol === 'https:' ? 'wss' : 'ws'}://${location.host}/socket`);
  socket.connect();
  const channel = socket.channel('ticker:btcusdt', {});

  let paused = false;

  // Chart.js setup
  const ctx = document.getElementById('priceChart').getContext('2d');
  const MAX_POINTS = 300; // ~5 minutes at ~1s average tick; Binance sends variable rate
  const data = {
    labels: [],
    datasets: [{
      label: 'Price (USDT)',
      data: [],
      borderColor: '#60a5fa',
      backgroundColor: 'rgba(96,165,250,0.08)',
      pointRadius: 0,
      borderWidth: 2,
      tension: 0.15,
      fill: true
    }]
  };
  const chart = new Chart(ctx, {
    type: 'line',
    data,
    options: {
      animation: false,
      maintainAspectRatio: false,
      scales: {
        x: {
          ticks: { color: '#94a3b8' },
          grid: { color: 'rgba(148,163,184,0.12)' }
        },
        y: {
          ticks: { color: '#94a3b8' },
          grid: { color: 'rgba(148,163,184,0.12)' }
        }
      },
      plugins: {
        legend: { display: false },
        tooltip: { mode: 'index', intersect: false }
      }
    }
  });

  function setStatus(kind, text) {
    el.status.classList.remove('ok', 'err');
    if (kind) el.status.classList.add(kind);
    el.status.textContent = text;
  }

  function upsertKpis(t) {
    if (!t) return;
    const price = Number(t.c || t.lastPrice || 0);
    const chgPerc = Number(t.P || t.priceChangePercent || 0);
    const chgAbs = Number(t.p || t.priceChange || 0);
    const high = Number(t.h || t.highPrice || 0);
    const low = Number(t.l || t.lowPrice || 0);
    const vol = Number(t.v || t.volume || 0);
    const quoteVol = Number(t.q || t.quoteVolume || 0);
    const ts = Number(t.E || t.eventTime || Date.now());

    el.price.textContent = price ? fmt.format(price) : '—';
    el.priceTime.textContent = `as of ${timeFmt.format(new Date(ts))}`;

    const sign = chgPerc >= 0 ? '+' : '';
    el.change.textContent = `${sign}${fmtPerc.format(chgPerc)}%`;
    el.change.style.color = chgPerc >= 0 ? '#22c55e' : '#f87171';
    el.changeAbs.textContent = `${chgAbs >= 0 ? '+' : ''}${fmt4.format(chgAbs)}`;

    el.high.textContent = high ? fmt.format(high) : '—';
    el.low.textContent = low ? fmt.format(low) : '—';
    el.vol.textContent = vol ? fmt.format(vol) : '—';
    el.quoteVol.textContent = quoteVol ? fmt.format(quoteVol) : '—';
  }

  function addFeedItem(t) {
    const price = Number(t.c || 0);
    const chgPerc = Number(t.P || 0);
    const ts = Number(t.E || Date.now());

    const li = document.createElement('li');
    li.innerHTML = `<span class="ts">${timeFmt.format(new Date(ts))}</span>
                    <span class="p">${fmt.format(price)}</span>
                    <span class="chg ${chgPerc>=0?'up':'down'}">${chgPerc>=0?'+':''}${fmtPerc.format(chgPerc)}%</span>`;
    el.feed.prepend(li);
    while (el.feed.children.length > 50) el.feed.removeChild(el.feed.lastChild);
  }

  function addChartPoint(t) {
    const price = Number(t.c || 0);
    const ts = Number(t.E || Date.now());
    data.labels.push(timeFmt.format(new Date(ts)));
    data.datasets[0].data.push(price);
    if (data.labels.length > MAX_POINTS) { data.labels.shift(); data.datasets[0].data.shift(); }
    chart.update();
  }

  function onTick(t) {
    if (!paused) {
      addChartPoint(t);
      addFeedItem(t);
    }
    upsertKpis(t);
  }

  channel.on('latest', onTick);
  channel.on('update', onTick);

  channel.join()
    .receive('ok', () => setStatus('ok', 'Live'))
    .receive('error', (e) => setStatus('err', 'Channel error'))
    .receive('timeout', () => setStatus('err', 'Timeout'));

  socket.onError(() => setStatus('err', 'Disconnected'));
  socket.onOpen(() => setStatus('ok', 'Live'));

  // Controls
  el.pauseBtn.addEventListener('click', () => {
    paused = !paused;
    el.pauseBtn.textContent = paused ? 'Resume' : 'Pause';
    el.pauseBtn.classList.toggle('btn-secondary', paused);
  });
  el.clearBtn.addEventListener('click', () => {
    data.labels = [];
    data.datasets[0].data = [];
    chart.update();
    el.feed.innerHTML = '';
  });
})();
