package {
    import flash.display.Sprite;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import FlashPC.GPU;
    import FlashPC.CPU;

    [SWF(width="640", height="480", backgroundColor="#cccccc", frameRate="60")]
    public class Main extends Sprite {
        private var gpu:GPU;
        private var cpu:CPU;

        public function Main() {
            init();
        }

        private function init():void {
            gpu = new GPU();
            cpu = new CPU(gpu);

            addChild(gpu);
            addChild(cpu);

            //loadAndExecuteScript("test.flasm");
        }

        private function loadAndExecuteScript(fileName:String):void {
            var file:File = File.applicationDirectory.resolvePath(fileName);
            var fileStream:FileStream = new FileStream();

            try {
                fileStream.open(file, FileMode.READ);
                var script:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
                cpu.loadAndExecuteScript(script);
            } catch (error:Error) {
                trace("Error loading or executing the script:", error.message);
            } finally {
                fileStream.close();
            }
        }
    }
}
