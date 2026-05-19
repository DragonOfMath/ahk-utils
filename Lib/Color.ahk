#Requires AutoHotkey >=2.0

/**
 * Basic class for working with pixel colors.
 * @class {Color}
 * @property {Integer} r - the red component
 * @property {Integer} g - the green component
 * @property {Integer} b - the blue component
 */
class Color {
	static ToNumber(red, green, blue) {
		return (red << 16) | (green << 8) | blue
	}
	static GetRGBComponents(int) {
		if (int is String) {
			int := Integer(int)
		}
		blue := Mod(int, 0x100)
		int := (int - blue) / 0x100
		green := Mod(int, 0x100)
		int := (int - green) / 0x100
		red := Mod(int, 0x100)
		return [red, green, blue]
	}
	static GetCMYComponents(red, green, blue) {
		if (red is Integer) {
			c := 0xFF - red
		} else {
			c := 1.0 - red
		}
		if (green is Integer) {
			m := 0xFF - green
		} else {
			m := 1.0 - green
		}
		if (blue is Integer) {
			y := 0xFF - blue
		} else {
			y := 1.0 - blue
		}
		return [c, m, y]
	}
	static GetHSLComponents(red, green, blue) {
		if (red is Integer) {
			r := red / 0xFF
		} else {
			r := red
		}
		if (green is Integer) {
			g := green / 0xFF
		} else {
			g := green
		}
		if (blue is Integer) {
			b := blue / 0xFF
		} else {
			b := blue
		}
		xmin := Min(r, g, b)
		xmax := Max(r, g, b)
		chroma := xmax - xmin
		hue := 0
		sat := 0
		light := (xmax + xmin) / 2
		if (chroma > 0) {
			if (xmax = r) {
				hue := 60 * (0 + (g - b) / chroma)
			} else if (xmax = g) {
				hue := 60 * (2 + (b - r) / chroma)
			} else {
				hue := 60 * (4 + (r - g) / chroma)
			}
			sat := 2 * (xmax - light) / (1 - Abs(2 * light - 1))
		}
		return [hue, sat, light]
	}
	static HSLtoRGB(hue, sat, light) {
		hue   := Mod(hue, 360)
		sat   := Min(Max(sat, 0), 1)
		light := Min(Max(light, 0), 1)
		
		h := hue / 60
		c := (1 - Abs(2 * light - 1)) * sat
		x := c * (1 - Abs(Mod(h, 2) - 1))
		r := 0
		g := 0
		b := 0
		switch Floor(h) {
			case 0: 
				r := c, g := x
			case 1: 
				r := x, g := c
			case 2: 
				g := c, b := x
			case 3: 
				g := x, b := c
			case 4: 
				b := c, r := x
			case 5: 
				b := x, r := c
		}
		m := light - c / 2
		r := Round(0xFF * (r + m))
		g := Round(0xFF * (g + m))
		b := Round(0xFF * (b + m))
		return [r, g, b]
	}

	__PRIVATE__ := ["red","green","blue","rgb","cyan","magenta","yellow","hue","sat","light","hsl"]

	__New(red := 0, green?, blue?) {
		if (red is Array) {
			blue := red[3]
			green := red[2]
			red := red[1]
		} else if (IsSet(green) and IsSet(blue)) {
			
		} else {
			comps := Color.GetRGBComponents(red)
			red := comps[1]
			green := comps[2]
			blue := comps[3]
		}
		this.r := red
		this.g := green
		this.b := blue
	}
	__Enum(*) {
		return [this.r, this.g, this.b]
	}
	__Item[comp] {
		get {
			if (comp is Integer) {
				switch comp {
					case 1: return this.r
					case 2: return this.g
					case 3: return this.b
					case -1: return this.cyan
					case -2: return this.magenta
					case -3: return this.yellow
					default: return 0
				}
			} else {
				return this.%comp%
			}
		}
		set {
			if (comp is Integer) {
				switch comp {
					case 1: this.r := value
					case 2: this.g := value
					case 3: this.b := value
					case -1: this.cyan := value
					case -2: this.magenta := value
					case -3: this.yellow := value
					default: return 0
				}
			} else {
				this.%comp% := value
			}
		}
	}
	
	red {
		get => this.r
		set => this.r := value
	}
	green {
		get => this.g
		set => this.g := value
	}
	blue {
		get => this.b
		set => this.b := value
	}
	rgb {
		get => Color.ToNumber(this.r, this.g, this.b)
		set {
			comps := Color.GetRGBComponents(value)
			this.r := comps[1]
			this.g := comps[2]
			this.b := comps[3]
		}
	}
	
	cyan {
		get => 0xFF - this.r
		set => this.r := 0xFF - value
	}
	magenta {
		get => 0xFF - this.g
		set => this.g := 0xFF - value
	}
	yellow {
		get => 0xFF - this.b
		set => this.b := 0xFF - value
	}
	cmy {
		get => Color.ToNumber(this.cyan, this.magenta, this.yellow)
		set {
			comps := Color.GetRGBComponents(value)
			this.cyan := comps[1]
			this.magenta := comps[2]
			this.yellow := comps[3]
		}
	}
	
	hue {
		get => this.hsl[1]
		set {
			hsl := this.hsl
			hsl[1] := value
			this.hsl := hsl
		}
	}
	sat {
		get => this.hsl[2]
		set {
			hsl := this.hsl
			hsl[1] := value
			this.hsl := hsl
		}
	}
	light {
		get => this.hsl[3]
		set {
			hsl := this.hsl
			hsl[2] := value
			this.hsl := hsl
		}
	}
	hsl {
		get => Color.GetHSLComponents(this.r, this.g, this.b)
		set {
			rgb := Color.HSLtoRGB(value*)
			this.r := rgb[1]
			this.g := rgb[2]
			this.b := rgb[3]
		}
	}
	
	ToString() {
		return Format("0x{1:02x}{2:02x}{3:02x}", this.r, this.g, this.b)
	}
	
	ToArray() {
		return [this.r, this.g, this.b]
	}
	
	Equals(color) {
		return this.r = color.r and this.g = color.g and this.b = color.b
	}
	
	DistanceEuclid(color) {
		dr := this.r - color.r
		dg := this.g - color.g
		db := this.b - color.b
		return Sqrt(dr * dr + dg * dg + db * db)
	}
	
	DistanceTaxicab(color) {
		dr := Abs(this.r - color.r)
		dg := Abs(this.g - color.g)
		db := Abs(this.b - color.b)
		return dr + dg + db
	}
	
	DistanceChebyshev(color) {
		dr := Abs(this.r - color.r)
		dg := Abs(this.g - color.g)
		db := Abs(this.b - color.b)
		return Max(dr, dg, db)
	}
	
	DistanceHamming(color) {
		dr := Abs(this.r - color.r)
		dg := Abs(this.g - color.g)
		db := Abs(this.b - color.b)
		return StrCount(Format("{1:b}{2:b}{3:b}", dr, dg, db), "1")
	}
}