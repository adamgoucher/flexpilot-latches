/*
Copyright 2009, Matthew Eernisse (mde@fleegix.org) and Slide, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

package org.flex_pilot {
  import flash.display.Sprite;
  import flash.display.Stage;
  import org.flex_pilot.FlexPilot;
  import org.flex_pilot.FPAssert;
  import org.flex_pilot.FPWait;
  import org.flex_pilot.astest.ASTest;
  public class TestCase extends Sprite {
    public var flex_pilot:* = FlexPilot;
    public var asserts:* = FPAssert; 
    public var waits:* = FPWait; 
    public var controller:* = ASTest.wrappedControllerMethods; 
    // Reference to either an Application (Flex)
    // or the Stage (Flash)
    public var context:* = FlexPilot.getContext();
    // Get a reference to the Stage in the base class
    // before the tests actually load so tests can all
    // reference it
    private var fakeStage:Stage = FlexPilot.getStage();
    override public function get stage():Stage {
      return fakeStage;
    }
  }
}

