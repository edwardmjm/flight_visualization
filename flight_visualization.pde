import java.util.*;
import java.util.Map.*;
//data
int n;
float dotSize, dotMax, dotMin;
float maxGraphElement;

HashMap <Integer, LinkedList <Airport>> clique = new HashMap <Integer, LinkedList <Airport>> ();

Airport []port;
HashMap <String, Integer> indexOfCity = new HashMap <String, Integer> ();

float mousePressX, mousePressY, mousePressL, mousePressR, mousePressU, mousePressD;

String []edgeData;
float [][]graph;
int []graphU;
int []graphV;


//param
int W = 960;
int H = 800;
float L = 0, R = W, U = 800, D = 0;
float rotAngle = HALF_PI; //+ PI;
float dotChange;

//control
int mouseMode = 0;

//Class
class Airport {
  float x, y;
  String name;
  Airport(float x, float y, String name) {
    this.x = x;
    this.y = y;
    this.name = name;
  }
}

void setup() {
  size(W,H);
  edgeData = loadStrings("airline.txt");
  smooth();
  noStroke();
  initAirPorts();
  buildGraph();
  sortEdge();
  dotSize=2;
  dotMax=3;
  dotMin=1;
  dotChange=0.1;
  L = W / 4; D = U / 4;
}
 
void draw() {
  background(0);
  drawAirline();
  drawAirport();
  transform();
  if (mousePressed) {
    float d = dist(mouseX, mouseY, mousePressX, mousePressY);
    noFill();
    stroke(255, 0, 0);
    ellipse((mouseX + mousePressX) / 2, (mouseY + mousePressY) / 2, d, d);
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getAmount();
  if (e < 0) {
    zoom(e);
  } else if (e > 0) {
    zoom(e);
  }
}

void mousePressed() {
  if (mouseMode == 0) {
    mousePressX = mouseX;
    mousePressY = mouseY;
    mousePressL = L;
    mousePressR = R;
    mousePressU = U;
    mousePressD = D;
  } else if (mouseMode == 1) {
    mousePressX = mouseX;
    mousePressY = mouseY;
  }
}

void mouseDragged() {
  if (mouseMode == 0) {
    float dx, dy, rate =  (R - L) / width;
    dx = (mouseX - mousePressX) * rate;
    dy = (mouseY - mousePressY) * rate;
    L = mousePressL - dx;
    R = mousePressR - dx;
    U = mousePressU - dy;
    D = mousePressD - dy;
  } else {
  }
}

void mouseReleased() {
  if (mouseMode == 1) {
    float mx = (mouseX + mousePressX) / 2;
    float my = (mouseY + mousePressY) / 2;
    float r = dist(mouseX, mouseY, mousePressX, mousePressY) / 2;
    LinkedList <Airport> v = new LinkedList <Airport> ();
    ArrayList <Airport> norm = new ArrayList <Airport> ();
    for (int i = 0; i < n; i++) {
      float x = transx(port[i].x);
      float y = transy(port[i].y);
      if (dist(x, y, mx, my) <= r) {
        if (clique.containsKey(i)) {
          for (Airport e : clique.get(i))
            v.add(e);
          clique.remove(i);
        } else {
          v.add(port[i]);
        }
      } else if (!clique.containsKey(i)) {
        norm.add(port[i]);
      }
    }
    mergeAirport(v, norm);
  }
}

void keyPressed() {
  if (key == '1') {
    mouseMode = 0;
  } else if (key == '2') {
    mouseMode = 1;
  }
}

void initAirPorts() {
  String dataLines[] = loadStrings("airports_gao_new.csv");
  n = dataLines.length - 1;
  float airportLon;
  float airportLat;
  port = new Airport[n];
  for (int counter = 0; counter < n; counter++) {
    String[] temp = split(dataLines[counter + 1], ',');
    indexOfCity.put(temp[0], counter);
    airportLat = float(temp[5]);
    airportLon = float(temp[6]);
    port[counter] = new Airport(map(airportLon, -170, 0, 150, width+300), map(airportLat, 20, 80, height-100, 0), temp[0]);
  }
}

void buildGraph() {
  String []data = edgeData;
  graph = new float [n][n];
  int m = data.length, cnt = 0;
  for (int i = 0; i < m; i++) {
    String[] tmp = split(data[i], ',');
    Integer u = indexOfCity.get(tmp[0]);
    Integer v = indexOfCity.get(tmp[1]);
    if (u != null && v != null) {
      cnt++;
      graph[u][v] += float(tmp[2]);
    }
  }
  graphU = new int[cnt];
  graphV = new int[cnt];
  cnt = 0;
  float minv = 1e20f;
  float maxv = -1e20f;
  for (int i = 0; i < m; i++) {
    String[] tmp = split(data[i], ',');
    Integer u = indexOfCity.get(tmp[0]);
    Integer v = indexOfCity.get(tmp[1]);
    if (u != null && v != null) {
      if (graph[u][v] < minv) minv = graph[u][v];
      if (graph[u][v] > maxv) maxv = graph[u][v];
      graphU[cnt] = u;
      graphV[cnt] = v;
      cnt++;
    }
  }
}

void sortEdge() {
  int m = graphU.length;
  for (int i = 0; i < m; i++) {
    for (int j = i + 1; j < m; j++) {
      if (graph[graphU[i]][graphV[i]] > graph[graphU[j]][graphV[j]]) {
        int tmp = graphU[i]; graphU[i] = graphU[j]; graphU[j] = tmp;
        tmp = graphV[i]; graphV[i] = graphV[j]; graphV[j] = tmp;
      }
    }
  }
  float minv = 1e20f;
  float maxv = -1e20f;
  for (int i = 0; i < m; i++) {
    int u = graphU[i];
    int v = graphV[i];
    if (graph[u][v] > maxv) maxv = graph[u][v];
    if (graph[u][v] < minv) minv = graph[u][v];
  }
  maxGraphElement = maxv;
  println(maxv + ", " + minv);
}

void mergeAirport(LinkedList <Airport> v, ArrayList <Airport> norm) {
  if (v.isEmpty()) return;
  HashMap <String, Integer> index = new HashMap <String, Integer> ();
  n = norm.size() + clique.size() + 1;
  port = new Airport[n];
  for (int i = 0; i < norm.size(); i++) {
    port[i] = norm.get(i);
    index.put(port[i].name, i);
  }
  int idx = norm.size();
  HashMap <Integer, LinkedList <Airport>> tmp = new HashMap <Integer, LinkedList <Airport>> ();
  for (Entry <Integer, LinkedList <Airport>> e : clique.entrySet())
    tmp.put(idx++, e.getValue());
  tmp.put(idx++, v);
  clique = tmp;
  idx = norm.size();
  for (Entry <Integer, LinkedList <Airport>> e : clique.entrySet()) {
    float sumx = 0, sumy = 0;
    for (Airport e2 : e.getValue()) {
      index.put(e2.name, idx);
      sumx += e2.x;
      sumy += e2.y;
    }
    port[idx++] = new Airport(sumx / e.getValue().size(), sumy / e.getValue().size(), new String());
  }
  indexOfCity = index;
  buildGraph();
  sortEdge();
}
 
void transform() {
  dotSize=dotSize+dotChange;
  if (dotSize>dotMax || dotSize<dotMin) {
    dotChange=dotChange*-1.0;
  }
}

void zoom(float rate) {
  if (rate < -5) rate = -5;
  if (rate > 5) rate = 5;
  if (!(rate >= -6 && rate <= 6)) return;
  float mx = (L + R) / 2;
  float my = (D + U) / 2;
  if (L >= R) {
    L = mx - width / 30.0;
    R = mx + width / 30.0;
  }
  if (D >= U) {
    D = my - height / 30.0;
    U = my + height / 30.0;
  }
  if (rate > 0) {
    if ((R - L) / width >= 3) return;
  } else if (rate < 0) {
    if (width / (R - L) >= 30) return;
  }
  rate = ((R - mx) + rate * 10) / (R - mx);
  L = (L - mx) * rate + mx;
  R = (R - mx) * rate + mx;
  U = (U - my) * rate + my;
  D = (D - my) * rate + my;
  println(L + " " + R + " " + D + " " + U);
}

void drawAirport() {
  smooth();
  noStroke();
  for (int i = 0; i < n; i++) { 
    fill(#F9FCAB);
    Ellipse(port[i].x, port[i].y, dotSize);
  }
}
 
void drawAirline() {
  int u, v;
  float tmp, x0, x1, y0, y1, d, mx, my, R, G, B, V, U, Y;
  PVector vec = new PVector(0, 0);
  noFill();
  for (int i = 0; i < graphU.length; i++) {
    u = graphU[i];
    v = graphV[i];
    x0 = port[u].x;
    y0 = port[u].y;
    x1 = port[v].x;
    y1 = port[v].y;
    if (x0 > x1) {
      tmp = x0; x0 = x1; x1 = tmp;
      tmp = y0; y0 = y1; y1 = tmp;
    }
    mx = (x0 + x1) / 2.0;
    my = (y0 + y1) / 2.0;
    vec.set(x1 - x0, y1 - y0);
    vec.rotate(rotAngle);
    vec.mult(2);
    mx += vec.x;
    my += vec.y;
    d = dist(x0, y0, mx, my);
    Y = changeV(graph[u][v]);
    if (Y < 30) continue;
    U = V = 0;
    R = Y + 1.14 * V;
    G = Y - 0.39 * U - 0.58 * V;
    B = Y + 2.03 * U;
    stroke(R, G, B);
    Arc(mx, my, d * 2, (new PVector(x0 - mx, y0 - my)).heading(), (new PVector(x1 - mx, y1 - my)).heading());
  }
}
//transform function
float changeV(float v) {
  return v / maxGraphElement * 255.0;
}

float transx(float x) {
  return (x - L) / (R - L) * width;
}

float transy(float y) {
  return (y - D) / (U - D) * height;
}

float revtransx(float x) {
  return x / width * (R - L) + L;
}

float revtransy(float y) {
  return y / height * (U - D) + D;
}

float transd(float d) {
  return d / (R - L) * width;
}

void Ellipse(float x, float y, float d) {
  ellipse(transx(x), transy(y), transd(d), transd(d));
}

void Arc(float x, float y, float d, float a0, float a1) {
  arc(transx(x), transy(y), transd(d), transd(d), a0, a1);
}

