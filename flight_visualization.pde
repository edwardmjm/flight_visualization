import java.util.*;
import java.util.concurrent.*;
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
  if (mousePressed && (mouseMode == 1 || mouseMode == 2)) {
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
  } else if (mouseMode == 1 || mouseMode == 2) {
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
  } else if (mouseMode == 2) {
    float mx = (mouseX + mousePressX) / 2;
    float my = (mouseY + mousePressY) / 2;
    float r = dist(mouseX, mouseY, mousePressX, mousePressY) / 2;
    ArrayList <Airport> norm = new ArrayList <Airport> ();
    for (int i = 0; i < n; i++) {
      float x = transx(port[i].x);
      float y = transy(port[i].y);
      if (dist(x, y, mx, my) <= r) {
        if (clique.containsKey(i)) {
          for (Airport e : clique.get(i))
            norm.add(e);
          clique.remove(i);
        } else {
          norm.add(port[i]);
        }
      } else if (!clique.containsKey(i)) {
        norm.add(port[i]);
      }
    }
    splitAirport(norm);
  }
}

void keyPressed() {
  if (key == '1') {
    mouseMode = 0;
  } else if (key == '2') {
    mouseMode = 1;
  } else if (key == '3') {
    mouseMode = 2;
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
  ArrayList <Integer> U = new ArrayList <Integer> (), V = new ArrayList <Integer> ();
  graph = new float [n][n];
  for (int i = 0; i < n; i++) for (int j = 0; j < n; j++) graph[i][j] = 0;
  int m = data.length;
  for (int i = 0; i < m; i++) {
    String[] tmp = split(data[i], ',');
    Integer u = indexOfCity.get(tmp[0]);
    Integer v = indexOfCity.get(tmp[1]);
    if (u != null && v != null && !u.equals(v)) {
      U.add(u);
      V.add(v);
      graph[v][u] = (graph[u][v] += float(tmp[2]));
    }
  }
  graphU = new int [U.size()];
  graphV = new int [V.size()];
  for (int i = 0; i < U.size(); i++) {
    graphU[i] = U.get(i);
    graphV[i] = V.get(i);
  }
}

void sortEdge() {
  int m = graphU.length;
  int []u = new int[m];
  int []v = new int[m];
  for (int i = 0; i < m; i++) {
    u[i] = graphU[i];
    v[i] = graphV[i];
  }
  for (int i = 0; i < m; i++) {
    for (int j = i + 1; j < m; j++) {
      if (graph[u[i]][v[i]] > graph[u[j]][v[j]]) {
        int tmp = u[i]; u[i] = u[j]; u[j] = tmp;
        tmp = v[i]; v[i] = v[j]; v[j] = tmp;
      }
    }
  }
  float maxv = -1e20f;
  int lhs = -1, rhs = -1;
  for (int i = 0; i < m; i++) {
    if (graph[u[i]][v[i]] > maxv) {
      maxv = graph[u[i]][v[i]];
      lhs = u[i];
      rhs = v[i];
    }
  }
  maxGraphElement = maxv;
  graphU = u;
  graphV = v;
  //println(maxv);
  //println(lhs + " --- " + rhs + " m = " + m);
}

void constructAirport(List <Airport> a, int idx, HashMap <String, Integer> index) {
  float sumx = 0, sumy = 0;
  for (Airport e : a) {
    index.put(e.name, idx);
    sumx += e.x;
    sumy += e.y;
  }
  port[idx] = new Airport(sumx / a.size(), sumy / a.size(), "");
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
  for (Entry <Integer, LinkedList <Airport>> e : clique.entrySet()) {
    tmp.put(idx, e.getValue());
    constructAirport(e.getValue(), idx++, index);
  }
  tmp.put(idx, v);
  constructAirport(v, idx, index);
  clique = tmp;
  indexOfCity = index;
  buildGraph();
  sortEdge();
}

void splitAirport(ArrayList <Airport> norm) {
  HashMap <String, Integer> index = new HashMap <String, Integer> ();
  n = norm.size() + clique.size();
  port = new Airport[n];
  for (int i = 0; i < norm.size(); i++) {
    port[i] = norm.get(i);
    index.put(port[i].name, i);
  }
  int idx = norm.size();
  HashMap <Integer, LinkedList <Airport>> tmp = new HashMap <Integer, LinkedList <Airport>> ();
  for (Entry <Integer, LinkedList <Airport>> e : clique.entrySet()) {
    tmp.put(idx, e.getValue());
    float sumx = 0, sumy = 0;
    for (Airport e2 : e.getValue()) {
      index.put(e2.name, idx);
      sumx += e2.x;
      sumy += e2.y;
    }
    port[idx++] = new Airport(sumx / e.getValue().size(), sumy / e.getValue().size(), new String());
  }
  clique = tmp;
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
}

void drawAirport() {
  smooth();
  noStroke();
  for (int i = 0; i < n; i++) { 
    if (!clique.containsKey(i)) {
      fill(#F9FCAB);
    } else {
      fill(255, 0, 0);
    }
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
  return map(x, L, R, 0, width);
  //return (x - L) / (R - L) * width;
}

float transy(float y) {
  return map(y, D, U, 0, height);
  //return (y - D) / (U - D) * height;
}

float revtransx(float x) {
  return map(x, 0, width, L, R);
  //return x / width * (R - L) + L;
}

float revtransy(float y) {
  return map(y, 0, height, D, U);
  //return y / height * (U - D) + D;
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

