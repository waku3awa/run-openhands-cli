import turtle
from turtle import Screen, Turtle

# スクリーンの設定
screen = Screen()
screen.setup(width=600, height=600)
screen.bgcolor("lightblue")
screen.title("猫のテストプログラム")

# タートルの作成
cat_turtle = Turtle()
cat_turtle.speed(3)
cat_turtle.color("black")

# 猫の顔を描く
def draw_cat_face():
    # 顔の輪郭（円）
    cat_turtle.penup()
    cat_turtle.goto(0, -100)
    cat_turtle.pendown()
    cat_turtle.circle(100)
    
    # 左耳
    cat_turtle.penup()
    cat_turtle.goto(-50, 50)
    cat_turtle.pendown()
    cat_turtle.setheading(60)
    cat_turtle.forward(40)
    cat_turtle.right(120)
    cat_turtle.forward(40)
    
    # 右耳
    cat_turtle.penup()
    cat_turtle.goto(50, 50)
    cat_turtle.pendown()
    cat_turtle.setheading(120)
    cat_turtle.forward(40)
    cat_turtle.right(120)
    cat_turtle.forward(40)
    
    # 左目
    cat_turtle.penup()
    cat_turtle.goto(-30, 20)
    cat_turtle.pendown()
    cat_turtle.dot(10)
    
    # 右目
    cat_turtle.penup()
    cat_turtle.goto(30, 20)
    cat_turtle.pendown()
    cat_turtle.dot(10)
    
    # 鼻
    cat_turtle.penup()
    cat_turtle.goto(0, 0)
    cat_turtle.pendown()
    cat_turtle.dot(8, "pink")
    
    # 口
    cat_turtle.penup()
    cat_turtle.goto(-15, -20)
    cat_turtle.pendown()
    cat_turtle.setheading(315)
    cat_turtle.circle(15, 90)
    
    cat_turtle.penup()
    cat_turtle.goto(15, -20)
    cat_turtle.pendown()
    cat_turtle.setheading(225)
    cat_turtle.circle(15, 90)

# テキストを表示する関数
def display_text():
    cat_turtle.penup()
    cat_turtle.goto(0, -200)
    cat_turtle.color("darkblue")
    cat_turtle.write("猫：にゃーニャー", align="center", font=("Arial", 24, "bold"))

# 猫の顔を描画
draw_cat_face()

# テキストを表示
display_text()

# タートルを隠す
cat_turtle.hideturtle()

# クリックで終了
screen.exitonclick()