package FlashPC
{
    import flash.display.Sprite;
    import flash.display.Graphics;

    public class GPU extends Sprite
    {
        private var graphicsBuffer:Graphics;

        public function GPU()
        {
            init();
        }

        private function init():void
        {
            graphicsBuffer = this.graphics;
        }

        public function drawRect(_color:uint, _x:int, _y:int, _width:int, _height:int):void
        {
            var rectangle:Sprite = new Sprite();
            rectangle.graphics.beginFill(_color);
            rectangle.graphics.drawRect(_x, _y, _width, _height);
            rectangle.graphics.endFill();
            addChild(rectangle);

            trace("Drawn rectangle at (" + _x + ", " + _y + ") with width: " + _width + ", height: " + _height);
        }

        public function drawCircle(_color:uint, _x:int, _y:int, _radius:int):void
        {
            var circle:Sprite = new Sprite();
            circle.graphics.beginFill(_color);
            circle.graphics.drawCircle(_x, _y, _radius);
            circle.graphics.endFill();
            addChild(circle);

            trace("Drawn circle at (" + _x + ", " + _y + ") with radius: " + _radius);
        }

        public function drawLine(_color:uint, _x1:int, _y1:int, _x2:int, _y2:int):void
        {
            var line:Sprite = new Sprite();
            line.graphics.lineStyle(2, _color);
            line.graphics.moveTo(_x1, _y1);
            line.graphics.lineTo(_x2, _y2);
            addChild(line);

            trace("Drawn line from (" + _x1 + ", " + _y1 + ") to (" + _x2 + ", " + _y2 + ")");
        }
    }
}
