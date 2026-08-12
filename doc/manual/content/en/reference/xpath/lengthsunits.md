---
title: "Lengths and units"
weight: 150
type: docs
---



The lengths can be given in one of these units: `pp`, `pc`, `in`, `pt`, `cm`, `mm`, `dd`, `cc`. Without the unit, lengths will be in grid cells.

| Unit | Description |
| --- | --- |
| pp | Pica Point |
| pc | Pica (12 pp) |
| in | Inch (72.27 pp) |
| px | Pixel (1/96 inch) |
| pt | Big point (72 bp = 1 in) PostScript point, DTP-point |
| cm | Centimeter |
| mm | Millimeter |
| dd | Didot point |
| cc | Cicero (12 dd) |
| sp | Scaled point, 1pp = 65536sp |



## Conversion

| Unit | Unit |
| --- | --- |
| 1  Pica-point | 0.35147 mm |
| 1  Pica-point | 1/72.27 inch |
| 1  Pica-point | 0.013837 inch |
| 1  Pica-point | 0.93457 Didot-point |
| 1  Pica | 4.2176 mm |
| 1  Pica | 1/6 inch |
| 1  Pica | 12 Pica point |
| 1  PostScript Point (Adobe, DTP-point) | 1.00375001 Pica Point = 1pt |
| 1  mm | 0.237 Pica = 2,845 Pica-point |

To convert units you can use the layout function `sd:tounit()`

### Converter

<div id="unit-converter">
<div style="display:flex; gap:0.8rem; align-items:center; flex-wrap:wrap; margin:1rem 0;">
  <input type="number" id="uc-input" value="1" step="any" style="width:8rem; padding:0.4rem 0.6rem; border:1px solid var(--color-gold); border-radius:4px; font-size:0.95rem; font-family:inherit;">
  <select id="uc-from" style="padding:0.4rem 0.6rem; border:1px solid var(--color-gold); border-radius:4px; font-size:0.95rem; font-family:inherit; background:var(--color-bg);">
    <option value="pt" selected>pt (DTP point)</option>
    <option value="mm">mm</option>
    <option value="cm">cm</option>
    <option value="in">in (inch)</option>
    <option value="pp">pp (Pica point)</option>
    <option value="pc">pc (Pica)</option>
    <option value="dd">dd (Didot)</option>
    <option value="cc">cc (Cicero)</option>
    <option value="px">px (Pixel)</option>
    <option value="sp">sp (Scaled point)</option>
  </select>
  <span style="font-size:1.2rem;">=</span>
  <span id="uc-result" style="font-weight:500; font-size:1.1rem;"></span>
  <select id="uc-to" style="padding:0.4rem 0.6rem; border:1px solid var(--color-gold); border-radius:4px; font-size:0.95rem; font-family:inherit; background:var(--color-bg);">
    <option value="pt">pt (DTP point)</option>
    <option value="mm" selected>mm</option>
    <option value="cm">cm</option>
    <option value="in">in (inch)</option>
    <option value="pp">pp (Pica point)</option>
    <option value="pc">pc (Pica)</option>
    <option value="dd">dd (Didot)</option>
    <option value="cc">cc (Cicero)</option>
    <option value="px">px (Pixel)</option>
    <option value="sp">sp (Scaled point)</option>
  </select>
</div>
</div>

<script>
(function() {
  // All units in terms of 1 inch
  var factors = {
    pt: 72,
    pp: 72.27,
    pc: 72.27 / 12,
    in: 1,
    cm: 2.54,
    mm: 25.4,
    dd: 72.27 / 0.376065,
    cc: 72.27 / (0.376065 * 12),
    px: 96,
    sp: 72.27 * 65536
  };
  function convert() {
    var val = parseFloat(document.getElementById('uc-input').value);
    var from = document.getElementById('uc-from').value;
    var to = document.getElementById('uc-to').value;
    if (isNaN(val)) { document.getElementById('uc-result').textContent = '–'; return; }
    var inches = val / factors[from];
    var result = inches * factors[to];
    var decimals = (to === 'sp') ? 0 : (Math.abs(result) >= 100 ? 2 : (Math.abs(result) >= 1 ? 4 : 6));
    document.getElementById('uc-result').textContent = parseFloat(result.toFixed(decimals)).toLocaleString('en-US');
  }
  document.getElementById('uc-input').addEventListener('input', convert);
  document.getElementById('uc-from').addEventListener('change', convert);
  document.getElementById('uc-to').addEventListener('change', convert);
  convert();
})();
</script>

