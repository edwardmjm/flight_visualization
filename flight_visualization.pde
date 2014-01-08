import java.util.*;
import java.util.concurrent.*;
import java.util.Map.*;

//param
int W = 720;
int H = 600;
float L = 0, R = W, U = H, D = 0;
float disPlayLength = 50;
float disPlayLength2 = 200;
static final float rotAngle = HALF_PI;
float dotChange;

//data
int n;
float dotSize, dotMax, dotMin;
float maxGraphElement;

HashMap <Integer, LinkedList <Airport>> clique = new HashMap <Integer, LinkedList <Airport>> ();

Airport []port;
HashMap <String, Integer> indexOfCity = new HashMap <String, Integer> ();
HashMap <String, Integer> indexOfState = new HashMap <String, Integer> ();

float mousePressX, mousePressY, mousePressL, mousePressR, mousePressU, mousePressD;
float refX = 0, refY = 0, refW = W, refH = H;

String []edgeData;
float [][]graph;
int []graphU;
int []graphV;

int [][]flow;

int stateCount;
State[] states;

float[] incomes;
float[] tourist;

//control
int mouseMode = 0;
int oldMouseMode;
int dataMode = 0, oldDataMode;

int noneBP = 300, noneLen = 20, incomeBP = 230, incomeLen = 50;
int flowBP = 160, flowLen = 20, tourBP = 100, tourLen = 20;

//color control
boolean resetPressed = false;

//Class
class Airport {
  float x, y;
  String name;
  String trueName;
  Airport(float x, float y, String name, String trueName) {
    this.x = x;
    this.y = y;
    this.name = name;
    this.trueName = trueName;
  }
}

class State{
  String name;
  String trueName;
  float x, y;
  State(float x, float y, String name, String trueName){
    this.x = x;
    this.y = y;
    this.name = name;
    this.trueName = trueName;
  }
}

void resetGraph() {
  indexOfCity.clear();
  indexOfState.clear();
  clique.clear();
  smooth();
  noStroke();
  initAirPorts();
  initState();
  initIncome();
  initFlow();
  initTourist();
  buildGraph();
  sortEdge();
  dotSize=2;
  dotMax=2;
  dotMin=1;
  dotChange=0.05;
  L = W / 4;
  D = H / 4;
  R = W;
  U = H;
}

void setGraphCoor(int x, int y, int w, int h) { //in pixel reference to the windows size.
  refX = x;
  refY = y;
  refW = w;
  refH = h;
}

void setup() {
  size(W,H);
  edgeData = loadStrings("airline.txt");
  resetGraph();
}

void draw() {
  background(0);
  drawData();
  drawAirport();
  drawStatusBar();
  drawText();
  transform();
  if (mousePressed && (mouseMode == 1 || mouseMode == 2)) {
    float d = dist(mouseX, mouseY, mousePressX, mousePressY);
    noFill();
    stroke(255, 0, 0);
    ellipse((mouseX + mousePressX) / 2, (mouseY + mousePressY) / 2, d, d);
  }
}

void mouseWheel(MouseEvent event) {
  if (mouseMode < 3) {
    float e = event.getAmount();
    if (e < 0) {
      zoom(e);
    } else if (e > 0) {
      zoom(e);
    }
  }
}

void mousePressed() {
  /* Statusbar Injection */
  if(mouseY >= H - 50){
    // Lock the mode
    oldMouseMode = mouseMode;
    mouseMode = 4;
    statusBarPressedEvent(mouseX, mouseY);
    return;
  }
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
    float dx, dy, rate =  (R - L) / refW;
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
  } else if(mouseMode == 4){
    statusBarReleaseEvent(mouseX, mouseY);
    mouseMode = oldMouseMode;
  }
}

void keyPressed() {
  if (key == '1') {
    mouseMode = 0;
  } else if (key == '2') {
    mouseMode = 1;
  } else if (key == '3') {
    mouseMode = 2;
  } else if (key == '4') {
    mouseMode = 3;
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
    port[counter] = new Airport(map(airportLon, -170, 0, 150, refW+300), map(airportLat, 20, 80, refH-100, 0), temp[0], temp[1]);
  }
}

void initState(){
  String dataStates[] = loadStrings("locationOfState.csv");
  stateCount = dataStates.length - 1;
  states = new State[stateCount];
  for(int i = 0; i < stateCount; ++i){
    String[] temp = split(dataStates[i + 1], ',');
    states[i] = new State(map(float(temp[3]), -170, 0, 150, refW+300), map(float(temp[2]), 20, 80, refH-100, 0), temp[1], temp[0]);
    indexOfState.put(temp[1], i);
  }
}

void initIncome(){
  String dataIncomes[] = loadStrings("IncomeByState.csv");
  incomes = new float[stateCount];
  for(int i = 0; i < stateCount; ++i){
    String[] temp = split(dataIncomes[i + 1], ',');
    //System.out.println(int(temp[2]));
    incomes[i] = map(int(temp[2]), 36919, 70004, 0, 10);
  }
}

void initTourist(){
  String dataTourist[] = loadStrings("tourismByState.csv");
  tourist = new float[stateCount];
  for(int i = 0; i < stateCount; ++i){
    String[] temp = split(dataTourist[i + 1], ',');
    tourist[i] = map(float(temp[1]), 0, 75, 0, 10);
  }
}

void initFlow() {
  String []dataFlow = loadStrings("stateinflow0910.csv");
  flow = new int[stateCount][stateCount];
  int off = 7;
  int n = dataFlow.length - off;
  for (int i = 0; i < n; i++) {
    String []temp = split(dataFlow[i + off], ','); 
    Integer u = indexOfState.get(temp[1]);
    Integer v = indexOfState.get(temp[3]);
    if (u != null && v != null && !u.equals(v)) {
      flow[u][v] += int(temp[7]);   //TODO TODECIDE
    }
  }
  int maxflow = 0, minflow = (int)1e9;
  for (int i = 0; i < stateCount; i++)
    for (int j = 0; j < stateCount; j++)
      if (i != j && flow[i][j] > 0) {
        if (flow[i][j] > maxflow) maxflow = flow[i][j];
        if (flow[i][j] < minflow) minflow = flow[i][j];
      }
  println("maxflow = " + maxflow);
  println("minflow = " + minflow);
  for (int i = 0; i < stateCount; i++) {
    for (int j = 0; j < stateCount; j++) {
      if (flow[i][j] > 0) {
        flow[i][j] = (int)map(flow[i][j], minflow, maxflow, 1, 100);
      }
    }
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
  port[idx] = new Airport(sumx / a.size(), sumy / a.size(), "", "");
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
    port[idx++] = new Airport(sumx / e.getValue().size(), sumy / e.getValue().size(), "", "");
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
    L = mx - refW / 30.0;
    R = mx + refW / 30.0;
  }
  if (D >= U) {
    D = my - refH / 30.0;
    U = my + refH / 30.0;
  }
  if (rate > 0) {
    if ((R - L) / refW >= 3) return;
  } else if (rate < 0) {
    if (refW / (R - L) >= 30) return;
  }
  rate = ((R - mx) + rate * 10) / (R - mx);
  L = (L - mx) * rate + mx;
  R = (R - mx) * rate + mx;
  U = (U - my) * rate + my;
  D = (D - my) * rate + my;
}

void drawText() {
  smooth();
  noStroke();
  for (int i = 0; i < n; i++)
    if (R - L <= disPlayLength) {
      fill(255, 0, 0);
      text(port[i].trueName, transx(port[i].x), transy(port[i].y));
    }
  for (int i = 0; i < stateCount; i++) {
    fill(255, 0, 0);
    if (R - L < disPlayLength2)
      text(states[i].trueName, transx(states[i].x), transy(states[i].y));
  }
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

void drawState() {
  smooth();
  noStroke();
  for(int i = 0; i < stateCount; ++i){
    fill(#436EEE);
    Ellipse(states[i].x, states[i].y, incomes[i]);
  }
}

void drawTourist() {
  smooth();
  noStroke();
  for(int i = 0; i < stateCount; ++i){
    fill(#436EEE);
    Ellipse(states[i].x, states[i].y, tourist[i]);
  }
}

void drawData(){
  if(dataMode == 0){
    drawAirline();
  } else if(dataMode == 1){
    drawAirline();
    drawState();
  } else if(dataMode == 2){
    drawFlow();
    drawAirline();
    drawState();
  } else if(dataMode == 3){
    drawTourist();
    drawAirline();
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

void drawFlow() {
  noFill();
  colorMode(RGB, 100);
  float Y, U, V, R, G, B;
  for (int u = 0; u < stateCount; u++) {
    for (int v = 0; v < stateCount; v++) {
      if (flow[u][v] > 0) {
        if (u == v) println("ERROR " + u);
        //TODO   set color
        R = flow[u][v];
        G = 100 - flow[u][v];
        B = 0;
        stroke(R, G, B);
        if (flow[u][v] < 20) continue;
        //stroke(255, 0, 0);
        float x0, y0, x1, y1, tmp, mx, my, d;
        x0 = states[u].x;
        y0 = states[u].y;
        x1 = states[v].x;
        y1 = states[v].y;
        PVector vec = new PVector();
        if (x0 > x1) {
          tmp = x0; x0 = x1; x1 = tmp;
          tmp = y0; y0 = y1; y1 = tmp;
          mx = (x0 + x1) / 2.0;
          my = (y0 + y1) / 2.0;
          vec.set(x1 - x0, y1 - y0);
          vec.rotate(rotAngle + PI);
          vec.mult(2);
          mx += vec.x;
          my += vec.y;
          d = dist(x0, y0, mx, my);
          MultiArc(mx, my, d * 2, (new PVector(x1 - mx, y1 - my)).heading(), (new PVector(x0 - mx, y0 - my)).heading());
        } else {
          mx = (x0 + x1) / 2.0;
          my = (y0 + y1) / 2.0;
          vec.set(x1 - x0, y1 - y0);
          vec.rotate(rotAngle);
          vec.mult(2);
          mx += vec.x;
          my += vec.y;
          d = dist(x0, y0, mx, my);
          MultiArc(mx, my, d * 2, (new PVector(x0 - mx, y0 - my)).heading(), (new PVector(x1 - mx, y1 - my)).heading());
        }
      }
    }
  }
  colorMode(RGB, 255);
  noStroke();
}

void drawStatusBar(){
  //Color
  color descColor = #CBCBCB; 
  color highlightColor = #CBCBCB;
  color unhighlightColor = #66664C;
  //A Rectangle to cover
  noStroke();
  fill(0);
  rect(0, H - 50, W, H);
  //Description Text
  textSize(16);
  textAlign(CENTER);
  fill(descColor);
  text("Indra's Net", W / 2, H - 25);
  // Description Text
  //textSize(12);
  fill((mouseMode == 0) ? highlightColor : unhighlightColor);
  text("Drag", W / 2 + 150, H - 25);
  fill((mouseMode == 1) ? highlightColor : unhighlightColor);
  text("Gain", W / 2 + 200, H - 25);
  fill((mouseMode == 2) ? highlightColor : unhighlightColor);
  text("Rcov", W / 2 + 250, H - 25);
  fill(resetPressed ? highlightColor : unhighlightColor);
  text("Reset", W - 50, H - 25);
  fill((dataMode == 0) ? highlightColor : unhighlightColor);
  text("None", W / 2 - noneBP, H - 25);
  fill((dataMode == 1) ? highlightColor : unhighlightColor);
  text("Income", W / 2 - incomeBP, H - 25);
  fill((dataMode == 2) ? highlightColor : unhighlightColor);
  text("Flow", W / 2 - flowBP, H - 25);
  fill((dataMode == 3) ? highlightColor : unhighlightColor);
  text("Tour", W / 2 - tourBP, H - 25);
}

void statusBarReleaseEvent(int x, int y){
  if(resetPressed){
    resetGraph();
    resetPressed = false;
  } else {
    // Data choosing
    if(x >= W / 2 - noneBP - noneLen && x <= W / 2 - noneBP + noneLen)
      dataMode = 0;
    else if(x >= W / 2 - incomeBP - incomeLen && x <= W / 2 - incomeBP + incomeLen)
      dataMode = 1;
    else if(x >= W / 2 - flowBP - flowLen && x <= W / 2 - flowBP + flowLen)
      dataMode = 2;
    else if(x >= W / 2 - tourBP - tourLen && x <= W / 2 - tourBP + tourLen)
      dataMode = 3;
  }
}

void statusBarPressedEvent(int x, int y){
  if(x > W - 80)
    resetPressed = true;
  else if(x > W / 2 + 130 && x < W / 2 + 170)
    oldMouseMode = 0;
  else if(x > W / 2 + 180 && x < W / 2 + 220)
    oldMouseMode = 1;
  else if(x > W / 2 + 230 && x < W / 2 + 270)
    oldMouseMode = 2;
}

//transform function
float changeV(float v) {
  return v / maxGraphElement * 255.0;
}

float transx(float x) {
  return map(x, L, R, refX, refX + refW);
}

float transy(float y) {
  return map(y, D, U, refY, refY + refH);
}

float revtransx(float x) {
  return map(x, refX, refX + refW, L, R);
}

float revtransy(float y) {
  return map(y, refY, refY + refH, D, U);
}

float transd(float d) {
  return d / (R - L) * refW;
}

void Ellipse(float x, float y, float d) {
  ellipse(transx(x), transy(y), transd(d), transd(d));
}

void Arc(float x, float y, float d, float a0, float a1) {
  arc(transx(x), transy(y), transd(d), transd(d), a0, a1);
}

void MultiArc(float x, float y, float d, float a0, float a1) {
  for (int i = 0; i < 3; i++)
    Arc(x + i, y + i, d, a0, a1);
}

