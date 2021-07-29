// BABEL FISH TOWER 3
// by arielm, May 2003
// http://www.chronotext.org

// December 2003: syntax adapted for processing 060+

float fovy, aspect;
float elevation, azimuth, distance;

Tower tower;

BFont f;

void setup()
{
  size(300, 300);
  framerate(20);
  //hint(SMOOTH_IMAGES);

  fovy = 60.0f;
  aspect = (float)width / (float)height;

  distance = 150.0f;
  elevation = radians(15.0f);
  azimuth = radians(-45.0f);

  String[] lines =
  {
    "A helix wrapped around a cyclotron",
    "Une spirale enroulee autour d'un cyclotron",
    "Eine um einen Teilchenbeschleuniger aufgerollte Spirale",
    "A spiral rolled up around a particle accelerator",
    "Une spirale s'est enroulee autour d'un accelarateur de particules",
    "Eine Spirale hat sich um einen Teilchenbeschleuniger aufgerollt"
  };

  color[] colors =
  {
    color(192, 192, 0),
    color(192, 0, 0),
    color(0, 192, 0),
    color(128, 128, 0),
    color(128, 0, 0),
    color(0, 128, 0)
  };

  f = loadFont("Univers65.vlw.gz");  // don't forget to have this font included in your "data" folder...

  tower = new Tower(0.0f, 30.0f, 0.0f, 3.0f, 75.0f, 25.0f, 66.667f, lines, colors, f, 10.0f, 2.0f);
}

void loop()
{
  background(255);

  beginCamera();
  perspective(fovy, aspect, 1.0f, 1000.0f);
  translate(0.0f, 0.0f, -distance);
  rotateX(-elevation);
  rotateY(-azimuth);
  endCamera();

  tower.run();

  //azimuth += radians(-2.0f);
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

    txt.font.size(txt.sz);

    colorMode(RGB, 255, 255, 255, 1);
    rouge = red(txt.col);
    vert = green(txt.col);
    bleu = blue(txt.col);

    while(index > 0)
    {
      ch = txt.line.charAt(--index);
      w = txt.font.width(ch);
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
        txt.font.text(ch, 0.0f, 0.0f, g);
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
    font.size(sz);
    return font.width(line);  // once kerning is implemented in P5, this one won't be accurate!
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
    boolean sliding;
    for (int i = 0; i < lines.length; i++)
    {
      sliding = helices[i].run();
      if (!sliding)
      {
        helices[i].speed *= 1.1f;
        helices[i].rewind(true, 0.0f);
        helices[i].start();
      }
    }
  }

  void build()
  {
    float in = 1.0;
    float out = 1.0;

    helices = new Helix[lines.length];
    for (int i = 0; i < lines.length; i++)
    {
      helices[i] = new Helix(x, y, z, turns * in, r1 * in, r2 * in, h * out, new Text(lines[i], font, colors[i], sz), speed);
      in -= 0.1f;
      out += 0.1f;
    }
  }

  void rewind()
  {
    float l = 0.0f;
    for (int i = 0; i < lines.length; i++)
    {
      helices[i].rewind(true, l);
      helices[i].start();

      l -= 10.0f;
    }
  }
}
