/**
 * Test class for TaskManagerController.
 * Provides comprehensive coverage for all CRUD operations with positive, negative, and bulk scenarios.
 */
@isTest
private class TaskManagerControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createAccount(true);
        TestDataFactory.createTasks(testAccount.Id, 251, true);
    }
    
    /**
     * Test getTasks with valid Account ID returns all tasks
     */
    @isTest
    static void shouldReturnTasks_WhenValidAccountId() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // When
        Test.startTest();
        List<Task> tasks = TaskManagerController.getTasks(testAccount.Id);
        Test.stopTest();
        
        // Then
        Assert.areEqual(100, tasks.size(), 'Should return maximum 100 tasks due to LIMIT clause');
        for (Task t : tasks) {
            Assert.areEqual(testAccount.Id, t.WhatId, 'All tasks should be associated with the test account');
            Assert.isNotNull(t.Subject, 'Task subject should not be null');
            Assert.isNotNull(t.Status, 'Task status should not be null');
            Assert.isNotNull(t.Priority, 'Task priority should not be null');
        }
    }
    
    /**
     * Test getTasks with null Account ID throws exception
     */
    @isTest
    static void shouldThrowException_WhenGetTasksWithNullAccountId() {
        // When/Then
        Test.startTest();
        try {
            TaskManagerController.getTasks(null);
            Assert.fail('Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Account ID cannot be null'), 
                'Exception message should indicate null account ID');
        }
        Test.stopTest();
    }
    
    /**
     * Test getTasks with non-existent Account ID returns empty list
     */
    @isTest
    static void shouldReturnEmptyList_WhenAccountHasNoTasks() {
        // Given
        Account newAccount = TestDataFactory.createAccount(true);
        
        // When
        Test.startTest();
        List<Task> tasks = TaskManagerController.getTasks(newAccount.Id);
        Test.stopTest();
        
        // Then
        Assert.areEqual(0, tasks.size(), 'Should return empty list for account with no tasks');
    }
    
    /**
     * Test createTask with valid data creates task successfully
     */
    @isTest
    static void shouldCreateTask_WhenValidData() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Task newTask = new Task(
            Subject = 'New Test Task',
            WhatId = testAccount.Id,
            Status = 'Not Started',
            Priority = 'High',
            ActivityDate = Date.today().addDays(7)
        );
        
        // When
        Test.startTest();
        Task createdTask = TaskManagerController.createTask(newTask);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(createdTask.Id, 'Created task should have an ID');
        Assert.areEqual('New Test Task', createdTask.Subject, 'Subject should match');
        Assert.areEqual('Not Started', createdTask.Status, 'Status should match');
        Assert.areEqual('High', createdTask.Priority, 'Priority should match');
        Assert.areEqual(testAccount.Id, createdTask.WhatId, 'Task should be associated with account');
        
        List<Task> allTasks = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id];
        Assert.areEqual(252, allTasks.size(), 'Total tasks should be 252 (251 from setup + 1 new)');
    }
    
    /**
     * Test createTask with null task throws exception
     */
    @isTest
    static void shouldThrowException_WhenCreateTaskWithNullTask() {
        // When/Then
        Test.startTest();
        try {
            TaskManagerController.createTask(null);
            Assert.fail('Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Task cannot be null'), 
                'Exception message should indicate null task');
        }
        Test.stopTest();
    }
    
    /**
     * Test createTask with blank subject throws exception
     */
    @isTest
    static void shouldThrowException_WhenCreateTaskWithBlankSubject() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Task newTask = new Task(
            Subject = '',
            WhatId = testAccount.Id,
            Status = 'Not Started',
            Priority = 'Normal'
        );
        
        // When/Then
        Test.startTest();
        try {
            TaskManagerController.createTask(newTask);
            Assert.fail('Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Subject is required'), 
                'Exception message should indicate subject is required');
        }
        Test.stopTest();
    }
    
    /**
     * Test createTask without WhatId throws exception
     */
    @isTest
    static void shouldThrowException_WhenCreateTaskWithoutAccountId() {
        // Given
        Task newTask = new Task(
            Subject = 'Test Task',
            Status = 'Not Started',
            Priority = 'Normal'
        );
        
        // When/Then
        Test.startTest();
        try {
            TaskManagerController.createTask(newTask);
            Assert.fail('Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('must be associated with an Account'), 
                'Exception message should indicate account association is required');
        }
        Test.stopTest();
    }
    
    /**
     * Test updateTaskStatus marks task as completed
     */
    @isTest
    static void shouldUpdateStatus_WhenMarkingTaskCompleted() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Task testTask = [SELECT Id, Status, IsClosed FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        Assert.areEqual('Not Started', testTask.Status, 'Initial status should be Not Started');
        
        // When
        Test.startTest();
        Task updatedTask = TaskManagerController.updateTaskStatus(testTask.Id, true);
        Test.stopTest();
        
        // Then
        Assert.areEqual('Completed', updatedTask.Status, 'Status should be updated to Completed');
        Assert.isTrue(updatedTask.IsClosed, 'Task should be marked as closed');
        
        Task verifyTask = [SELECT Status, IsClosed FROM Task WHERE Id = :testTask.Id];
        Assert.areEqual('Completed', verifyTask.Status, 'Database record should reflect Completed status');
    }
    
    /**
     * Test updateTaskStatus marks task as not completed
     */
    @isTest
    static void shouldUpdateStatus_WhenMarkingTaskNotCompleted() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Task testTask = TestDataFactory.createTaskWithFields(
            testAccount.Id, 
            'Completed Task', 
            'Normal', 
            'Completed', 
            Date.today(), 
            true
        );
        Assert.areEqual('Completed', testTask.Status, 'Initial status should be Completed');
        
        // When
        Test.startTest();
        Task updatedTask = TaskManagerController.updateTaskStatus(testTask.Id, false);
        Test.stopTest();
        
        // Then
        Assert.areEqual('Not Started', updatedTask.Status, 'Status should be updated to Not Started');
        
        Task verifyTask = [SELECT Status FROM Task WHERE Id = :testTask.Id];
        Assert.areEqual('Not Started', verifyTask.Status, 'Database record should reflect Not Started status');
    }
    
    /**
     * Test updateTaskStatus with null task ID throws exception
     */
    @isTest
    static void shouldThrowException_WhenUpdateStatusWithNullTaskId() {
        // When/Then
        Test.startTest();
        try {
            TaskManagerController.updateTaskStatus(null, true);
            Assert.fail('Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Task ID cannot be null'), 
                'Exception message should indicate null task ID');
        }
        Test.stopTest();
    }
    
    /**
     * Test updateTaskStatus with null completion status throws exception
     */
    @isTest
    static void shouldThrowException_WhenUpdateStatusWithNullCompletionStatus() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        
        // When/Then
        Test.startTest();
        try {
            TaskManagerController.updateTaskStatus(testTask.Id, null);
            Assert.fail('Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Completion status cannot be null'), 
                'Exception message should indicate null completion status');
        }
        Test.stopTest();
    }
    
    /**
     * Test updateTaskStatus with invalid task ID throws exception
     */
    @isTest
    static void shouldThrowException_WhenUpdateStatusWithInvalidTaskId() {
        // Given
        Id fakeTaskId = '00T000000000000AAA';
        
        // When/Then
        Test.startTest();
        try {
            TaskManagerController.updateTaskStatus(fakeTaskId, true);
            Assert.fail('Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Task not found or access denied'), 
                'Exception message should indicate task not found');
        }
        Test.stopTest();
    }
    
    /**
     * Test deleteTask successfully removes task
     */
    @isTest
    static void shouldDeleteTask_WhenValidTaskId() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        Integer initialCount = [SELECT COUNT() FROM Task WHERE WhatId = :testAccount.Id];
        Assert.areEqual(251, initialCount, 'Initial task count should be 251');
        
        // When
        Test.startTest();
        TaskManagerController.deleteTask(testTask.Id);
        Test.stopTest();
        
        // Then
        Integer finalCount = [SELECT COUNT() FROM Task WHERE WhatId = :testAccount.Id];
        Assert.areEqual(250, finalCount, 'Task count should be reduced by 1');
        
        List<Task> deletedTasks = [SELECT Id FROM Task WHERE Id = :testTask.Id];
        Assert.areEqual(0, deletedTasks.size(), 'Deleted task should not exist in database');
    }
    
    /**
     * Test deleteTask with null task ID throws exception
     */
    @isTest
    static void shouldThrowException_WhenDeleteTaskWithNullTaskId() {
        // When/Then
        Test.startTest();
        try {
            TaskManagerController.deleteTask(null);
            Assert.fail('Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Task ID cannot be null'), 
                'Exception message should indicate null task ID');
        }
        Test.stopTest();
    }
    
    /**
     * Test deleteTask with invalid task ID throws exception
     */
    @isTest
    static void shouldThrowException_WhenDeleteTaskWithInvalidTaskId() {
        // Given
        Id fakeTaskId = '00T000000000000AAA';
        
        // When/Then
        Test.startTest();
        try {
            TaskManagerController.deleteTask(fakeTaskId);
            Assert.fail('Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Task not found or access denied'), 
                'Exception message should indicate task not found');
        }
        Test.stopTest();
    }
    
    /**
     * Bulk test: Create multiple tasks to verify bulkification
     */
    @isTest
    static void shouldHandleBulkOperations_WhenMultipleTasksCreated() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Integer initialCount = [SELECT COUNT() FROM Task WHERE WhatId = :testAccount.Id];
        
        // When
        Test.startTest();
        for (Integer i = 0; i < 10; i++) {
            Task newTask = new Task(
                Subject = 'Bulk Task ' + i,
                WhatId = testAccount.Id,
                Status = 'Not Started',
                Priority = 'Normal'
            );
            TaskManagerController.createTask(newTask);
        }
        Test.stopTest();
        
        // Then
        Integer finalCount = [SELECT COUNT() FROM Task WHERE WhatId = :testAccount.Id];
        Assert.areEqual(initialCount + 10, finalCount, 'Should have 10 additional tasks');
    }
}