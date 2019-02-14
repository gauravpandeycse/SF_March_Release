/**
 * Created by garth.james on 03/05/2018.
 */

public with sharing class AssignCaseToMeController {
    PageReference cancel;
    Case[] cases;

    //Constructor for this class
    public AssignCaseToMeController(ApexPages.StandardSetController controller) {
        Cases = (Case[])controller.getSelected();
        cancel = controller.cancel();
    }

    //method called from the page to assign owner. Has no other usage
    public PageReference updateCases() {
        for(Case c: cases) {
            c.OwnerId = UserInfo.getUserId();
        }
        try {
            update cases;
        } catch(Exception ex) {
            String errorMessage = Label.FailedToAssignCase + ' ' + ex.getMessage();
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, errorMessage));
            DebugLog.addException(ex, 'AssignCaseToMeController: ' + errorMessage);
            return null;
        }
        return cancel.setRedirect(true);
    }
}