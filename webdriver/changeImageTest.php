<?php
// Copyright 2012-present Element 34
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

require_once('PHPWebDriver/WebDriver.php');
require_once('PHPWebDriver/WebDriverWait.php');
require_once('PHPWebDriver/Support/FlashFlex/FlexPilot.php');

class changeImageTest extends PHPUnit_Framework_TestCase {
    protected static $session;
    protected static $fp;

    public function setUp() {
        $driver = new PHPWebDriver_WebDriver();
        self::$session = $driver->session();
        self::$session->open("http://127.0.0.1:8000/index.html");

        $e = self::$session->element("name", "latches");

        self::$fp = new PHPWebDriver_WebDriver_Support_FlashFlex_FlexPilot(self::$session, $e);
        self::$fp->wait_for_flex_ready();
    }

    public function tearDown() {
        self::$session->close();
    }
    
    /**
    * @group latch
    */
    public function testPhotoChanging() {
        $chain = "id:button";
        self::$fp->click($chain);
        $w = new PHPWebDriver_WebDriverWait(self::$session, 10, 0.5, array("movie" => self::$fp->movie));
        $w->until(
            function($session, $extra_arguments) {
                $status = $session->execute(array(
                                              "script" => 'return arguments[0].WebDriverLatch("slideshow");',
                                              "args" => array(array("ELEMENT" => $extra_arguments["movie"]->getID()))
                                              )
                                          );
                if ($status == "changed") {
                    return true;
                }
                return false;
            }
        );
    }

}
