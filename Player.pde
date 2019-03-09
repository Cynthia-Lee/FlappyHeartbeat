class Player{
  float ycor;
  boolean dead = false;
  float ySpeed;
  

  Player() {
    //health = 5;
    ycor = 400;
    ySpeed = 0;
  }

  void jump(){
     ySpeed=-5; 
  }
  void drag(){
     ySpeed+=0.1; 
  }
  void move(){
    ycor+=ySpeed; 
    //for(int i = 0;i<3;i++){
      //p[i].xPos-=3;
    //}
  }
  void checkCollisions(){
    //circle(55,(int)ycor+50,7);
    if(get(100,(int)ycor+15) != color(eggshell)||get(55,(int)ycor) != color(eggshell)||get(55,(int)ycor+50) != color(eggshell)){
      dead = true;
    }
  }
}
