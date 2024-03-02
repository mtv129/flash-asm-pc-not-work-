package FlashPC
{
    import flash.display.*;
    import flash.utils.*;

    /**
     * Класс Memory представляет собой виртуальную память для использования в проектах на ActionScript.
     * Этот класс позволяет создавать и управлять буфером памяти для виртуального процессора.
    */
    public class Memory extends Sprite
    {
        // Буфер памяти
        private var memoryBuffer:ByteArray = new ByteArray();

        /**
         * Конструктор класса Memory. Вызывает инициализацию буфера памяти.
        */
        public function Memory()
        {
            init();
        }

        /**
         * Инициализация буфера памяти. Устанавливает начальный размер буфера в 1 мегабайт.
        */
        private function init():void {
            memoryBuffer.length = 1024 * 1024; // 1 мегабайт (32 бита на байт)
        }

        /**
         * Метод для чтения данных из виртуальной памяти.
         * @param address Адрес начала чтения в памяти.
         * @param length Количество байт, которые следует прочитать.
         * @return ByteArray с прочитанными данными.
         * @throws Error, если попытка чтения выходит за пределы буфера памяти.
        */
        public function readMemory(address:uint, length:uint):ByteArray {
            if (address + length > memoryBuffer.length) {
                throw new Error("Attempt to read beyond memory bounds.");
            }

            var data:ByteArray = new ByteArray();
            memoryBuffer.position = address;
            memoryBuffer.readBytes(data, 0, length);
            return data;
        }

        /**
         * Метод для записи данных в виртуальную память.
         * @param address Адрес начала записи в память.
         * @param data ByteArray с данными для записи в память.
         * @throws Error, если попытка записи выходит за пределы буфера памяти.
        */
        public function writeMemory(address:uint, data:ByteArray):void {
            if (address + data.length > memoryBuffer.length) {
                throw new Error("Attempt to write beyond memory bounds.");
            }

            memoryBuffer.position = address;
            memoryBuffer.writeBytes(data, 0, data.length);
        }
    }
}