/*
  Created by: Gordon Child
  Created: January 31, 2013

  This is meant to be a simple handler for cross site communication
*/

global class OssoVerifyController {

  global Boolean useEasyXDM {get;set;}
  global class OssoVerifyControllerException extends Exception{}
  global void initialize() {
    if(ApexPages.currentPage().getParameters().get('iframe') != null) {
      useEasyXDM = true;
    } else {
      useEasyXDM = false;
    }
  }

  global OssoVerifyController() {}
}