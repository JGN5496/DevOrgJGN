/**
 * Provides services for managing Task records related to Account records.
 * Supports CRUD operations with proper security and error handling.
 */
public with sharing class TaskManagerController {
    
    /**
     * Retrieves all tasks associated with a given Account ID.
     * 
     * @param accountId The ID of the Account to retrieve tasks for
     * @return List of Task records ordered by ActivityDate descending
     * @example
     * List<Task> tasks = TaskManagerController.getTasks('0011234567890ABC');
     */
    @AuraEnabled(cacheable=true)
    public static List<Task> getTasks(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account ID cannot be null');
        }
        
        try {
            return [
                SELECT Id, Subject, Status, Priority, ActivityDate, 
                       Description, IsClosed, CreatedDate
                FROM Task
                WHERE WhatId = :accountId
                WITH USER_MODE
                ORDER BY ActivityDate DESC NULLS LAST, CreatedDate DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving tasks: ' + e.getMessage());
        }
    }
    
    /**
     * Creates a new Task record associated with an Account.
     * 
     * @param task The Task record to create (must have WhatId set to Account ID)
     * @return The created Task record with its new ID
     * @throws AuraHandledException if creation fails or validation errors occur
     * @example
     * Task newTask = new Task(Subject='Follow up', WhatId=accountId, Priority='Normal');
     * Task created = TaskManagerController.createTask(newTask);
     */
    @AuraEnabled
    public static Task createTask(Task task) {
        if (task == null) {
            throw new AuraHandledException('Task cannot be null');
        }
        
        if (String.isBlank(task.Subject)) {
            throw new AuraHandledException('Task Subject is required');
        }
        
        if (task.WhatId == null) {
            throw new AuraHandledException('Task must be associated with an Account');
        }
        
        try {
            Database.SaveResult result = Database.insert(task, AccessLevel.USER_MODE);
            
            if (!result.isSuccess()) {
                String errorMessage = 'Error creating task';
                if (!result.getErrors().isEmpty()) {
                    errorMessage += ': ' + result.getErrors()[0].getMessage();
                }
                throw new AuraHandledException(errorMessage);
            }
            
            return [
                SELECT Id, Subject, Status, Priority, ActivityDate, 
                       Description, IsClosed, CreatedDate
                FROM Task
                WHERE Id = :result.getId()
                WITH USER_MODE
                LIMIT 1
            ];
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating task: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error creating task: ' + e.getMessage());
        }
    }
    
    /**
     * Updates the status of a Task record and marks it as closed/open.
     * 
     * @param taskId The ID of the Task to update
     * @param isCompleted True to mark as completed, false to mark as not completed
     * @return The updated Task record
     * @throws AuraHandledException if update fails
     * @example
     * Task updated = TaskManagerController.updateTaskStatus('00T1234567890ABC', true);
     */
    @AuraEnabled
    public static Task updateTaskStatus(Id taskId, Boolean isCompleted) {
        if (taskId == null) {
            throw new AuraHandledException('Task ID cannot be null');
        }
        
        if (isCompleted == null) {
            throw new AuraHandledException('Completion status cannot be null');
        }
        
        try {
            Task taskToUpdate = [
                SELECT Id, Status, IsClosed
                FROM Task
                WHERE Id = :taskId
                WITH USER_MODE
                LIMIT 1
            ];
            
            taskToUpdate.Status = isCompleted ? 'Completed' : 'Not Started';
            
            Database.SaveResult result = Database.update(taskToUpdate, AccessLevel.USER_MODE);
            
            if (!result.isSuccess()) {
                String errorMessage = 'Error updating task status';
                if (!result.getErrors().isEmpty()) {
                    errorMessage += ': ' + result.getErrors()[0].getMessage();
                }
                throw new AuraHandledException(errorMessage);
            }
            
            return [
                SELECT Id, Subject, Status, Priority, ActivityDate, 
                       Description, IsClosed, CreatedDate
                FROM Task
                WHERE Id = :taskId
                WITH USER_MODE
                LIMIT 1
            ];
        } catch (QueryException e) {
            throw new AuraHandledException('Task not found or access denied');
        } catch (DmlException e) {
            throw new AuraHandledException('Error updating task: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error updating task: ' + e.getMessage());
        }
    }
    
    /**
     * Deletes a Task record by its ID.
     * 
     * @param taskId The ID of the Task to delete
     * @throws AuraHandledException if deletion fails
     * @example
     * TaskManagerController.deleteTask('00T1234567890ABC');
     */
    @AuraEnabled
    public static void deleteTask(Id taskId) {
        if (taskId == null) {
            throw new AuraHandledException('Task ID cannot be null');
        }
        
        try {
            Task taskToDelete = [
                SELECT Id
                FROM Task
                WHERE Id = :taskId
                WITH USER_MODE
                LIMIT 1
            ];
            
            Database.DeleteResult result = Database.delete(taskToDelete, AccessLevel.USER_MODE);
            
            if (!result.isSuccess()) {
                String errorMessage = 'Error deleting task';
                if (!result.getErrors().isEmpty()) {
                    errorMessage += ': ' + result.getErrors()[0].getMessage();
                }
                throw new AuraHandledException(errorMessage);
            }
        } catch (QueryException e) {
            throw new AuraHandledException('Task not found or access denied');
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting task: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting task: ' + e.getMessage());
        }
    }
}