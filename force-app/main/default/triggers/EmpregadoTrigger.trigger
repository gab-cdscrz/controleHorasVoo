trigger EmpregadoTrigger on Empregado__c (before insert, before update, after insert, after update, before delete) {
    if(!TriggerControl.naoExecutarTrigger){
        if(Trigger.isBefore){
            if(Trigger.isInsert){
                EmpregadoTriggerHandler.handleBeforeInsert(Trigger.new);
            }
            if(Trigger.isUpdate)
                EmpregadoTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
            
            if (Trigger.isDelete)
                EmpregadoTriggerHandler.handleBeforeDelete(Trigger.oldMap);
        }
        else {
            if (Trigger.isInsert)
                EmpregadoTriggerHandler.handleAfterInsert(Trigger.new);
            else if (Trigger.isUpdate)
                EmpregadoTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}