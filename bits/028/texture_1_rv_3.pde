// TEXTURE 1, REV 3
// by arielm - May 30, 2003
// http://www.chronotext.org

// REV 2 - June 2, 2003: using dynamic (yet static) text written with the standard vlw fonts...
// REV 2 - June 2, 2003: badShape is still (and will stay) dumb, but is more aware of its length...

// caution: FontManager is based on undocumented features of Processing (could not work with anything else than 0054...)

// lyrics by Peter Gabriel / Genesis...

float fovy, aspect;
float elevation, azimuth, distance;

BImage img;
float sz, len;

void setup()
{
  size(300, 300);
  framerate(20.0);
  background(0);
  //hint(SMOOTH_IMAGES);  // will crash 0054

  fovy = 60.0;
  aspect = (float) width / (float) height;

  distance = 200.0;
  elevation = radians(285.0);
  azimuth = radians(0.0);

  FontManager fm = new FontManager();
  BFont fnt = fm.getFont("Univers65.vlw.gz");
  String txt = "Six saintly shrouded men, moved across the lawn slowly, the seventh walks in front with a cross held high in hand...";
  int w = fm.getStringWidth(fnt, txt);

  img = new BImage(new int[w * 64], w, 64, ALPHA);
  fm.drawString(fnt, img, txt);

  sz = 16.0;
  len = w / 64.0 * sz;
}

void loop()
{
  beginCamera();
  perspective(fovy, aspect, 1.0, 1000.0);
  translate(0.0, 0.0, -distance);
  rotateX(-elevation);
  rotateZ(-azimuth);
  endCamera();

  fill(255, 153, 0);
  drawBadShape(img, 0.0, 0.0, 50.0, 60.0, sz, len, radians(15.0));
  fill(255);
  drawBadShape(img, 0.0, 0.0, 40.0, 90.0, sz, len, radians(12.0));
  fill(153, 153, 255);
  drawBadShape(img, 0.0, 0.0, 30.0, 120.0, sz, len, radians(9.0));

  azimuth += radians(-1.0);
}

void drawBadShape(BImage bi, float x, float y, float z, float r, float h, float len, float dd)
{
  // dd is controlling L.O.D (level of distance)

  boolean b = false;
  float xx, yy, uu;

  noStroke();
  beginShape(QUAD_STRIP);
  textureImage(bi);
  for (float d = 0.0; d < len / r + dd; d += dd)
  {
    b = !b;
    xx = x + cos(d) * r;
    yy = y - sin(d) * r;
    uu = d * r * bi.height / h;
    vertexTexture(uu, b ? (float) bi.height : 0.0); vertex(xx, yy, b ? z : z + h); 
    vertexTexture(uu, b ? 0.0 : (float) bi.height); vertex(xx, yy, b ? z + h : z); 

    z -= 1.25;
  }
  endShape();
}

// ---

class FontManager
{
  static final int CAPACITY = 10;

  String[] names = new String[CAPACITY];
  BFont[] fonts = new BFont[CAPACITY];
  int count = 0;

  FontManager() {}

  BFont getFont(String name)
  {
    for (int i = 0; i < count; i++)
    {
      if (names[i] == name)
      {
        return fonts[i];
      }
    }

    BFont font = loadFont(name);
    names[count] = name;
    fonts[count] = font;
    return font;
  }

  int getCharWidth(BFont f, char c)
  {
    return c == ' ' ? getCharWidth(f, 'i') : f.setWidth[c - 33];
  }

  void drawChar(BFont f, BImage dest, char c, int x)
  {
    if (c == ' ')
    {
      return;
    }

    int[] p = f.images[c - 33].pixels;
    int[] dp = dest.pixels;

    int w = f.width[c - 33];
    int h = f.height[c - 33];
    int le = f.leftExtent[c - 33];
    int te = f.topExtent[c - 33];

    int ox = x;
    if (le > 0)
    {
      ox += le * 2;
      le = -le;
    }
    int oy = f.mboxY - te;
    int i1 = oy * dest.width;
    int i2 = 0;
    int w1 = w + le;

    for (int i = 0; i < h; i++)
    {
      for (int j = 0; j < w1; j++)
      {
        dp[ox + j + i1] = p[j - le + i2];
      }
      i1 += dest.width;
      i2 += 64;
    }
  }

  int getStringWidth(BFont f, String s)
  {
    int w = 0;
    for (int i = 0; i < s.length(); i ++)
    {
      w += getCharWidth(f, s.charAt(i));
    }
    return w;
  }

  void drawString(BFont f, BImage dest, String s)
  {
    int x = 0;
    char c;
    for (int i = 0; i < s.length(); i++)
    {
      c = s.charAt(i);
      drawChar(f, dest, c, x);
      x += getCharWidth(f, c);
    }
  }
}

