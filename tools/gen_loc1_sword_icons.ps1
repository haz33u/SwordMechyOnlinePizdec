# Loc1 anime inventory sword icons (System.Drawing)
# - Full blade always inside safe padding (no tip cut-off)
# - Cel-shade anime look: hard outline, flat bands, edge shine, glow by rarity

Add-Type -AssemblyName System.Drawing

$OutDir = Join-Path $PSScriptRoot "..\art\icons\weapons"
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function New-Color([string]$hex, [int]$a = 255) {
	$h = $hex.TrimStart('#')
	$r = [Convert]::ToInt32($h.Substring(0, 2), 16)
	$g = [Convert]::ToInt32($h.Substring(2, 2), 16)
	$b = [Convert]::ToInt32($h.Substring(4, 2), 16)
	return [Drawing.Color]::FromArgb($a, $r, $g, $b)
}

function Shift-Color([Drawing.Color]$c, [int]$d) {
	return [Drawing.Color]::FromArgb(255,
		[math]::Min(255, [math]::Max(0, $c.R + $d)),
		[math]::Min(255, [math]::Max(0, $c.G + $d)),
		[math]::Min(255, [math]::Max(0, $c.B + $d)))
}

function New-Pt([float]$x, [float]$y) {
	return New-Object Drawing.PointF $x, $y
}

# Build a classic anime longsword polygon fully inside [pad..size-pad]
# Tip at top-right, pommel bottom-center-left — scaled to fit.
function Get-BladePoly {
	param(
		[string]$Shape,
		[float]$Size = 512,
		[float]$Pad = 56
	)
	# Normalized design space 0..1 (tip ~ top-right, grip ~ bottom)
	# Then map into padded square with slight diagonal.
	$norm = @()
	switch ($Shape) {
		"stick" {
			# wooden training blade — wider, blunt tip
			$norm = @(
				@(0.42, 0.78), @(0.48, 0.72), @(0.58, 0.38), @(0.64, 0.22),
				@(0.70, 0.18), @(0.74, 0.24), @(0.66, 0.40), @(0.54, 0.74), @(0.48, 0.80)
			)
		}
		"cleaver" {
			$norm = @(
				@(0.40, 0.76), @(0.48, 0.58), @(0.52, 0.32), @(0.58, 0.18),
				@(0.78, 0.16), @(0.82, 0.28), @(0.72, 0.48), @(0.58, 0.72), @(0.48, 0.80)
			)
		}
		"curved" {
			# saber / fang — curve but tip stays inside
			$norm = @(
				@(0.42, 0.78), @(0.46, 0.62), @(0.48, 0.42), @(0.54, 0.26),
				@(0.66, 0.16), @(0.78, 0.14), @(0.80, 0.22), @(0.70, 0.30),
				@(0.58, 0.44), @(0.52, 0.62), @(0.50, 0.80)
			)
		}
		"great" {
			$norm = @(
				@(0.40, 0.78), @(0.46, 0.60), @(0.50, 0.34), @(0.56, 0.18),
				@(0.66, 0.12), @(0.74, 0.14), @(0.76, 0.24), @(0.68, 0.36),
				@(0.58, 0.58), @(0.52, 0.80)
			)
		}
		"crystal" {
			$norm = @(
				@(0.42, 0.76), @(0.48, 0.56), @(0.52, 0.34), @(0.60, 0.18),
				@(0.72, 0.12), @(0.78, 0.18), @(0.74, 0.28), @(0.64, 0.40),
				@(0.56, 0.58), @(0.50, 0.80)
			)
		}
		"arc" {
			$norm = @(
				@(0.40, 0.78), @(0.46, 0.58), @(0.48, 0.36), @(0.56, 0.20),
				@(0.70, 0.12), @(0.82, 0.14), @(0.84, 0.22), @(0.72, 0.28),
				@(0.60, 0.42), @(0.54, 0.60), @(0.50, 0.80)
			)
		}
		default {
			# short / long classic anime sword
			$norm = @(
				@(0.42, 0.78), @(0.48, 0.60), @(0.52, 0.36), @(0.58, 0.20),
				@(0.68, 0.12), @(0.76, 0.14), @(0.78, 0.22), @(0.70, 0.32),
				@(0.60, 0.52), @(0.54, 0.72), @(0.50, 0.80)
			)
		}
	}

	$inner = $Size - 2 * $Pad
	$pts = @()
	foreach ($n in $norm) {
		$x = $Pad + $n[0] * $inner
		$y = $Pad + $n[1] * $inner
		$pts += (New-Pt $x $y)
	}
	return ,$pts
}

function Get-GuardCenter([Drawing.PointF[]]$bladePts) {
	# near base of blade (high Y points average of last few / mid-bottom)
	$sumX = 0.0; $sumY = 0.0; $c = 0
	foreach ($p in $bladePts) {
		if ($p.Y -gt 340) {
			$sumX += $p.X; $sumY += $p.Y; $c++
		}
	}
	if ($c -eq 0) {
		return @{ X = 256.0; Y = 380.0 }
	}
	return @{ X = ($sumX / $c); Y = ($sumY / $c) - 8 }
}

function Draw-SoftGlow([Drawing.Graphics]$g, [Drawing.PointF[]]$pts, [Drawing.Color]$c, [int]$level) {
	if ($level -le 0) { return }
	# Center of poly for radial-ish aura via thick strokes
	$cx = 0.0; $cy = 0.0
	foreach ($p in $pts) { $cx += $p.X; $cy += $p.Y }
	$cx /= $pts.Count; $cy /= $pts.Count

	for ($i = $level + 3; $i -ge 1; $i--) {
		$alpha = [int](12 + 18 * ($i / ($level + 3.0)))
		$w = 10 + $i * (6 + $level)
		$pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B)), $w
		$pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
		$pen.StartCap = [Drawing.Drawing2D.LineCap]::Round
		$pen.EndCap = [Drawing.Drawing2D.LineCap]::Round
		$g.DrawPolygon($pen, $pts)
		$pen.Dispose()
	}

	# outer halo ellipse (stays inside canvas)
	$halo = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(18 + $level * 6, $c.R, $c.G, $c.B))
	$g.FillEllipse($halo, ($cx - 90 - $level * 8), ($cy - 110 - $level * 6), (180 + $level * 16), (220 + $level * 12))
	$halo.Dispose()
}

function Draw-CelBlade {
	param(
		[Drawing.Graphics]$g,
		[Drawing.PointF[]]$pts,
		[Drawing.Color]$base,
		[Drawing.Color]$accent,
		[bool]$Wood,
		[int]$Glow
	)

	$path = New-Object Drawing.Drawing2D.GraphicsPath
	$path.AddPolygon($pts)

	# shadow band (left/bottom of blade)
	$dark = Shift-Color $base -55
	$mid = $base
	$light = Shift-Color $base 75
	if ($light.R -lt 40 -and $light.G -lt 40 -and $light.B -lt 40) {
		$light = Shift-Color $base 110
	}

	# main fill gradient anime metal
	$br = New-Object Drawing.Drawing2D.LinearGradientBrush (
		(New-Object Drawing.Point 180, 400),
		(New-Object Drawing.Point 380, 80),
		$dark,
		$light
	)
	$g.FillPath($br, $path)
	$br.Dispose()

	# hard cel band (middle strip) — anime look
	$region = New-Object Drawing.Region $path
	$g.SetClip($region, [Drawing.Drawing2D.CombineMode]::Intersect)
	$cel = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(55, $light.R, $light.G, $light.B))
	# diagonal highlight band
	$g.FillPolygon($cel, @(
		(New-Pt 250 120), (New-Pt 300 100), (New-Pt 280 380), (New-Pt 230 390)
	))
	$cel.Dispose()

	# white specular edge (anime shine)
	$shine = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(210, 255, 255, 255)), 5
	$shine.StartCap = [Drawing.Drawing2D.LineCap]::Round
	$shine.EndCap = [Drawing.Drawing2D.LineCap]::Round
	$g.DrawLine($shine, 290, 130, 265, 360)
	$shine.Dispose()

	# secondary thinner shine
	$shine2 = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(100, 255, 255, 255)), 2
	$g.DrawLine($shine2, 305, 150, 285, 320)
	$shine2.Dispose()

	if ($Wood) {
		$grain = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(70, 50, 30, 10)), 2
		for ($t = 0; $t -lt 8; $t++) {
			$y0 = 150 + $t * 28
			$g.DrawLine($grain, 250, $y0, 290, $y0 - 35)
		}
		$grain.Dispose()
	}

	# energy edge for Rare+
	if ($Glow -ge 2) {
		$edge = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(140 + $Glow * 15, $accent.R, $accent.G, $accent.B)), (3 + $Glow)
		$edge.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
		$g.DrawPath($edge, $path)
		$edge.Dispose()
	}

	$g.ResetClip()
	$region.Dispose()

	# thick anime outline (outside)
	$outline = New-Object Drawing.Pen (New-Color "#0B0C10"), 7
	$outline.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
	$g.DrawPath($outline, $path)
	$outline.Dispose()

	# inner soft outline for pop
	$inner = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(80, 255, 255, 255)), 2
	$inner.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
	$g.DrawPath($inner, $path)
	$inner.Dispose()

	$path.Dispose()
}

function Draw-AnimeGuardGrip {
	param(
		[Drawing.Graphics]$g,
		[hashtable]$Center,
		[Drawing.Color]$Accent,
		[Drawing.Color]$Grip,
		[string]$Shape,
		[int]$Glow
	)

	$gx = [float]$Center.X
	$gy = [float]$Center.Y
	$outlineC = New-Color "#0B0C10"

	# Guard width by shape
	$gw = 72
	if ($Shape -eq "great") { $gw = 96 }
	if ($Shape -eq "stick") { $gw = 0 }
	if ($Shape -eq "cleaver") { $gw = 80 }
	if ($Shape -eq "arc") { $gw = 88 }

	if ($gw -gt 0) {
		# anime cross-guard bar
		$guardPath = New-Object Drawing.Drawing2D.GraphicsPath
		$guardPath.AddPolygon(@(
			(New-Pt ($gx - $gw / 2) ($gy - 6)),
			(New-Pt ($gx - $gw / 2 + 8) ($gy - 16)),
			(New-Pt ($gx + $gw / 2 - 8) ($gy - 16)),
			(New-Pt ($gx + $gw / 2) ($gy - 6)),
			(New-Pt ($gx + $gw / 2 - 6) ($gy + 12)),
			(New-Pt ($gx - $gw / 2 + 6) ($gy + 12))
		))
		$gBrush = New-Object Drawing.Drawing2D.LinearGradientBrush (
			(New-Object Drawing.Point ([int]($gx - $gw / 2)), ([int]$gy)),
			(New-Object Drawing.Point ([int]($gx + $gw / 2)), ([int]$gy)),
			(Shift-Color $Accent -30),
			(Shift-Color $Accent 50)
		)
		$g.FillPath($gBrush, $guardPath)
		$gBrush.Dispose()
		$op = New-Object Drawing.Pen $outlineC, 6
		$op.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
		$g.DrawPath($op, $guardPath)
		$op.Dispose()
		$guardPath.Dispose()

		# side orbs (anime tsuba accents)
		$orb = New-Object Drawing.SolidBrush (Shift-Color $Accent 40)
		$g.FillEllipse($orb, ($gx - $gw / 2 - 10), ($gy - 14), 22, 22)
		$g.FillEllipse($orb, ($gx + $gw / 2 - 12), ($gy - 14), 22, 22)
		$g.DrawEllipse((New-Object Drawing.Pen $outlineC, 4), ($gx - $gw / 2 - 10), ($gy - 14), 22, 22)
		$g.DrawEllipse((New-Object Drawing.Pen $outlineC, 4), ($gx + $gw / 2 - 12), ($gy - 14), 22, 22)
		$orb.Dispose()
	}

	# Grip
	$gripW = 30
	$gripH = 78
	$gripX = $gx - $gripW / 2
	$gripY = $gy + 8
	$gBrush2 = New-Object Drawing.Drawing2D.LinearGradientBrush (
		(New-Object Drawing.Point ([int]$gripX), ([int]$gripY)),
		(New-Object Drawing.Point ([int]($gripX + $gripW)), ([int]$gripY)),
		(Shift-Color $Grip -25),
		(Shift-Color $Grip 35)
	)
	$g.FillRectangle($gBrush2, $gripX, $gripY, $gripW, $gripH)
	$gBrush2.Dispose()
	$g.DrawRectangle((New-Object Drawing.Pen $outlineC, 5), $gripX, $gripY, $gripW, $gripH)

	# wrap lines (anime grip tape)
	$wrap = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(160, 0, 0, 0)), 3
	for ($yy = $gripY + 10; $yy -lt ($gripY + $gripH - 8); $yy += 11) {
		$g.DrawLine($wrap, ($gripX + 2), $yy, ($gripX + $gripW - 2), $yy)
	}
	$wrap.Dispose()
	# light wrap highlight
	$wrapH = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(70, 255, 255, 255)), 1
	for ($yy = $gripY + 12; $yy -lt ($gripY + $gripH - 8); $yy += 11) {
		$g.DrawLine($wrapH, ($gripX + 4), ($yy - 2), ($gripX + $gripW - 6), ($yy - 2))
	}
	$wrapH.Dispose()

	# Pommel gem
	$pr = 20
	if ($Glow -ge 4) { $pr = 24 }
	$px = $gx - $pr
	$py = $gripY + $gripH - 6
	$pomOuter = New-Object Drawing.SolidBrush $Accent
	$g.FillEllipse($pomOuter, $px, $py, $pr * 2, $pr * 2)
	$pomOuter.Dispose()
	$g.DrawEllipse((New-Object Drawing.Pen $outlineC, 5), $px, $py, $pr * 2, $pr * 2)
	# gem core shine
	$core = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(200, 255, 255, 255))
	$g.FillEllipse($core, ($px + $pr * 0.35), ($py + $pr * 0.3), ($pr * 0.7), ($pr * 0.55))
	$core.Dispose()
	if ($Glow -ge 3) {
		$ring = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(160, $Accent.R, $Accent.G, $Accent.B)), 3
		$g.DrawEllipse($ring, ($px - 4), ($py - 4), ($pr * 2 + 8), ($pr * 2 + 8))
		$ring.Dispose()
	}
}

function Draw-Sparkles([Drawing.Graphics]$g, [Drawing.Color]$c, [int]$Glow) {
	if ($Glow -lt 3) { return }
	$brush = New-Object Drawing.SolidBrush $c
	$white = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(220, 255, 255, 255))
	$spots = @(
		@(110, 140), @(400, 120), @(420, 260), @(100, 280), @(390, 360),
		@(130, 200), @(380, 180)
	)
	$n = [math]::Min($spots.Count, 3 + $Glow)
	for ($i = 0; $i -lt $n; $i++) {
		$s = $spots[$i]
		$sz = 6 + ($i % 3) * 3 + $Glow
		$g.FillEllipse($brush, $s[0], $s[1], $sz, $sz)
		$g.FillEllipse($white, ($s[0] + 2), ($s[1] + 2), [math]::Max(2, $sz / 3), [math]::Max(2, $sz / 3))
	}
	# 4-point star accents
	if ($Glow -ge 4) {
		$pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(200, $c.R, $c.G, $c.B)), 3
		foreach ($s in @(@(150, 100), @(370, 90), @(410, 200))) {
			$g.DrawLine($pen, ($s[0] - 10), $s[1], ($s[0] + 10), $s[1])
			$g.DrawLine($pen, $s[0], ($s[1] - 10), $s[0], ($s[1] + 10))
		}
		$pen.Dispose()
	}
	$brush.Dispose()
	$white.Dispose()
}

function Draw-SwordIcon {
	param(
		[string]$Id,
		[string]$Shape,
		[string]$BladeHex,
		[string]$AccentHex,
		[string]$GripHex,
		[int]$Glow = 0,
		[bool]$Wood = $false
	)

	$size = 512
	$pad = 56  # hard safe margin — blade tip/pommel never leave canvas
	$bmp = New-Object Drawing.Bitmap $size, $size
	$g = [Drawing.Graphics]::FromImage($bmp)
	$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
	$g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
	$g.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality

	# dark anime UI plate
	$g.Clear((New-Color "#14171E"))
	# soft inner circle
	$plate = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(28, 255, 255, 255))
	$g.FillEllipse($plate, 48, 48, 416, 416)
	$plate.Dispose()

	$bladeC = New-Color $BladeHex
	$accent = New-Color $AccentHex
	$gripC = New-Color $GripHex

	$bladePts = Get-BladePoly -Shape $Shape -Size $size -Pad $pad

	# verify bounds (safety clamp)
	for ($i = 0; $i -lt $bladePts.Count; $i++) {
		$x = [math]::Min($size - $pad, [math]::Max($pad, $bladePts[$i].X))
		$y = [math]::Min($size - $pad, [math]::Max($pad, $bladePts[$i].Y))
		$bladePts[$i] = New-Pt $x $y
	}

	Draw-SoftGlow $g $bladePts $accent $Glow
	Draw-CelBlade -g $g -pts $bladePts -base $bladeC -accent $accent -Wood $Wood -Glow $Glow

	$center = Get-GuardCenter $bladePts
	# keep guard/grip in pad
	if ($center.Y -gt ($size - $pad - 100)) { $center.Y = $size - $pad - 100 }
	if ($center.Y -lt 300) { $center.Y = 360 }

	Draw-AnimeGuardGrip -g $g -Center $center -Accent $accent -Grip $gripC -Shape $Shape -Glow $Glow
	Draw-Sparkles $g $accent $Glow

	# thin outer card rim (inventory feel)
	$rim = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(50, 255, 255, 255)), 2
	$g.DrawRectangle($rim, 8, 8, $size - 16, $size - 16)
	$rim.Dispose()

	$pathOut = Join-Path $OutDir "$Id.png"
	$bmp.Save($pathOut, [Drawing.Imaging.ImageFormat]::Png)
	$g.Dispose()
	$bmp.Dispose()
	Write-Host "OK $Id (glow=$Glow shape=$Shape)"
}

# ── Loc1 forest set ──────────────────────────────────────────────
# Glow: 0 Common · 1 Uncommon · 2 Rare · 3 Epic · 4 Legendary · 5 Mythic/Secret/Limited

Draw-SwordIcon -Id "W1_C1" -Shape "short"   -BladeHex "#9A8A78" -AccentHex "#6A6058" -GripHex "#4A3828" -Glow 0
Draw-SwordIcon -Id "W1_C2" -Shape "stick"   -BladeHex "#C49A5A" -AccentHex "#8B6238" -GripHex "#5A3E28" -Glow 0 -Wood $true
Draw-SwordIcon -Id "W1_U1" -Shape "short"   -BladeHex "#8A929C" -AccentHex "#3ECF6A" -GripHex "#3A2E24" -Glow 1
Draw-SwordIcon -Id "W1_U2" -Shape "cleaver" -BladeHex "#E0E6F0" -AccentHex "#A0B0C8" -GripHex "#3A3A48" -Glow 1
Draw-SwordIcon -Id "W1_R1" -Shape "long"    -BladeHex "#6B5B9A" -AccentHex "#A78BFF" -GripHex "#2A2040" -Glow 2
Draw-SwordIcon -Id "W1_R2" -Shape "curved"  -BladeHex "#E8EEF8" -AccentHex "#4DD4FF" -GripHex "#3A342C" -Glow 2
Draw-SwordIcon -Id "W1_E1" -Shape "long"    -BladeHex "#6EFFA0" -AccentHex "#2EFF7A" -GripHex "#1E3828" -Glow 3
Draw-SwordIcon -Id "W1_E2" -Shape "crystal" -BladeHex "#40FFB0" -AccentHex "#00F0C0" -GripHex "#183830" -Glow 3
Draw-SwordIcon -Id "W1_L1" -Shape "great"   -BladeHex "#FFE89A" -AccentHex "#FFC030" -GripHex "#3A2C14" -Glow 4
Draw-SwordIcon -Id "W1_L2" -Shape "long"    -BladeHex "#B8FF70" -AccentHex "#80FF40" -GripHex "#283818" -Glow 4
Draw-SwordIcon -Id "W1_M1" -Shape "great"   -BladeHex "#FF6AA0" -AccentHex "#FF3D9A" -GripHex "#2A1020" -Glow 5
Draw-SwordIcon -Id "W1_M2" -Shape "curved"  -BladeHex "#C060FF" -AccentHex "#FF50F0" -GripHex "#1A1030" -Glow 5
Draw-SwordIcon -Id "W1_S1" -Shape "crystal" -BladeHex "#FFF6B0" -AccentHex "#FFE040" -GripHex "#3A3010" -Glow 5
Draw-SwordIcon -Id "W1_S2" -Shape "great"   -BladeHex "#FFE8C0" -AccentHex "#FFD060" -GripHex "#3A2810" -Glow 5
Draw-SwordIcon -Id "W1_X1" -Shape "arc"     -BladeHex "#FF90F0" -AccentHex "#40F8FF" -GripHex "#201028" -Glow 5

Write-Host "Done → $OutDir"
