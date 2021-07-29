// BABEL FISH TOWER 1
// by arielm, May 2003
// http://www.chronotext.org

float fovy, aspect;
float elevation, azimuth, distance;

Tower tower;

BFont f;

void setup()
{
  size(300, 300);
  background(255);
  framerate(20);
  //hint(SMOOTH_IMAGES);

  fovy = 60.0f;
  aspect = (float)width / (float)height;

  distance = 160.0f;
  elevation = radians(15.0f);
  azimuth = radians(-45.0f);

  String[] lines =
  {
    "La tour de Babel Fish",
    "The tower of Babel Fish",
    "Der Aufsatz der Babel Fische",
    "L'essai des Babel de poissons",
    "The test of fish Babel",
    "Der Test der Fische Babel"
  };

  color[] colors =
  {
    color(204, 0, 0),
    color(204, 204, 0),
    color(0, 204, 0),
    color(127, 0, 0),
    color(127, 127, 0),
    color(0, 127, 0)
  };

  f = loadFont("Univers65.vlw.gz");  // don't forget to have this font included in your "data" folder...

  tower = new Tower(0.0f, 30.0f, 0.0f, 9.0f, 75.0f, 25.0f, 100.0f, lines, colors, f, 10.0f, 3.0f);
}

void loop()
{
  beginCamera();
  perspective(fovy, aspect, 1.0f, 1000.0f);
  translate(0.0f, 0.0f, -distance);
  rotateX(-elevation);
  rotateY(-azimuth);
  endCamera();

  tower.run();
}

class Helix
{
  float x, y, z, turns, r1, r2, h;

  Text txt;
  float offset, speed;
  boolean sliding;

  float d, D, r, l, L, dy, dr;
  boolean conical;
  int index;
  char ch;
  float w;
  float rouge, vert, bleu;

  Helix(float x, float y, float z, float turns, float r1, float r2, float h, Text txt, float speed)
  {
    this.x = x;
    this.y = y;
    this.z = z;
    this.turns = turns;
    this.r1 = r1;
    this.r2 = r2;
    this.h = h;

    this.txt = txt;
    this.speed = speed;
  }

  boolean run()
  {
    if (sliding)
    {
      draw();

      if (offset >= L)
      {
        stop();
      }
      else
      {
        offset += speed;
        return true;
      }
    }

    return false;
  }

  void draw()
  {
    D = offset;

    l = TWO_PI * turns;
    L = PI * turns * (r1 + r2);
    dy = -h / l;

    conical = (abs(r1 - r2) > 0.5);  // avoids infinity and divisions by zero with cylindrical helices (r1 = r2)
    if (conical)
    {
      dr = (r2 - r1) / l;
    }
    else
    {
      r = r1;
    }

    index = txt.line.length();
    char ch;

    txt.font.setSize(txt.sz);

    colorMode(RGB, 255, 255, 255, 1);
    rouge = red(txt.col);
    vert = green(txt.col);
    bleu = blue(txt.col);

    while(index > 0)
    {
      ch = txt.line.charAt(--index);
      w = txt.font.charWidth(ch);
      D += w;

      if (D + w > L)
      {
        break;
      }

      if (D >= w)
      {
        if (conical)
        {
          r = sqrt(r1 * r1 + 2.0 * dr * D);
          d = (r - r1) / dr;
        }
        else
        {
          d = D / r;
        }

        fill(rouge, vert, bleu, 0.6 + 0.4 * cos(azimuth + d));  // simple depth effect...

        push();
        translate(x - sin(d) * r, y + d * dy, z + cos(d) * r);
        rotateY(-d);
        rotateZ(atan2(h , l * r));  // banking...
        txt.font.drawChar(ch, 0.0f, 0.0f);
        pop();
      }
    }
  }

  void rewind(boolean invisible, float indent)
  {
    offset = indent;

    if (invisible)
    {
      offset -= txt.getWidth();
    }
  }

  void start()
  {
    sliding = true;
  }

  void stop()
  {
    sliding = false;
  }
}

class Text
{
  String line;
  BFont font;
  color col;
  float sz;

  Text(String line, BFont font, color col, float sz)
  {
    this.line = line;
    this.font = font;
    this.col = col;
    this.sz = sz;
  }

  float getWidth()
  {
      font.setSize(sz);
      return font.stringWidth(line);  // once kerning is implemented in P5, this one won't be accurate!
   }
}

class Tower
{
  float x, y, z, turns, r1, r2, h;

  String[] lines;
  color[] colors;
  BFont font;
  float sz;

  float speed;

  Helix[] helices;

  Tower(float x, float y, float z, float turns, float r1, float r2, float h, String[] lines, color[] colors, BFont font, float sz, float speed)
  {
    this.x = x;
    this.y = y;
    this.z = z;
    this.turns = turns;
    this.r1 = r1;
    this.r2 = r2;
    this.h = h;

    this.lines = lines;
    this.colors = colors;
    this.font = font;
    this.sz = sz;

    this.speed = speed;

    build();
    rewind();
  }

  void run()
  {
    boolean sliding = false;
    for (int i = 0; i < lines.length; i++)
    {
      sliding |= helices[i].run();
    }
    if (!sliding)
    {
      rewind();
    }
  }

  void build()
  {
    float l = TWO_PI * turns;
    float dr = (r2 - r1) / l;
    float dy = -h / l;

    helices = new Helix[lines.length];
    for (int i = 0; i < lines.length; i++)
    {
      helices[i] = new Helix(x, y + (TWO_PI * (float)i) * dy, z, turns - (float)i, r1 + (TWO_PI * (float)i) * dr, r2, h + (TWO_PI * (float)i) * dy, new Text(lines[i], font, colors[i], sz), speed);
    }
  }

  void rewind()
  {
    for (int i = 0; i < lines.length; i++)
    {
      helices[i].rewind(true, 0.0f);
      helices[i].start();
    }
  }
}
