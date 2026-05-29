/**
 * Factory class for creating test data across all test classes.
 * Centralizes test record creation to ensure consistency and maintainability.
 */
@isTest
public class TestDataFactory {
    
    /**
     * Creates a list of Account records.
     * 
     * @param count Number of accounts to create
     * @param doInsert Whether to insert records into the database
     * @return List of Account records
     */
    public static List<Account> createAccounts(Integer count, Boolean doInsert) {
        List<Account> accounts = new List<Account>();
        
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology',
                NumberOfEmployees = 100 + i
            ));
        }
        
        if (doInsert) {
            insert accounts;
        }
        
        return accounts;
    }
    
    /**
     * Creates a single Account record.
     * 
     * @param doInsert Whether to insert the record into the database
     * @return Account record
     */
    public static Account createAccount(Boolean doInsert) {
        Account acc = new Account(
            Name = 'Test Account',
            Industry = 'Technology',
            NumberOfEmployees = 100
        );
        
        if (doInsert) {
            insert acc;
        }
        
        return acc;
    }
    
    /**
     * Creates a list of Task records associated with an Account.
     * 
     * @param accountId The Account ID to associate tasks with
     * @param count Number of tasks to create
     * @param doInsert Whether to insert records into the database
     * @return List of Task records
     */
    public static List<Task> createTasks(Id accountId, Integer count, Boolean doInsert) {
        List<Task> tasks = new List<Task>();
        
        for (Integer i = 0; i < count; i++) {
            tasks.add(new Task(
                Subject = 'Test Task ' + i,
                WhatId = accountId,
                Status = 'Not Started',
                Priority = i < count / 2 ? 'High' : 'Normal',
                ActivityDate = Date.today().addDays(i)
            ));
        }
        
        if (doInsert) {
            insert tasks;
        }
        
        return tasks;
    }
    
    /**
     * Creates a single Task record associated with an Account.
     * 
     * @param accountId The Account ID to associate the task with
     * @param doInsert Whether to insert the record into the database
     * @return Task record
     */
    public static Task createTask(Id accountId, Boolean doInsert) {
        Task task = new Task(
            Subject = 'Test Task',
            WhatId = accountId,
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today().addDays(7)
        );
        
        if (doInsert) {
            insert task;
        }
        
        return task;
    }
    
    /**
     * Creates a Task with custom field values.
     * 
     * @param accountId The Account ID to associate the task with
     * @param subject The task subject
     * @param priority The task priority
     * @param status The task status
     * @param dueDate The task due date
     * @param doInsert Whether to insert the record into the database
     * @return Task record
     */
    public static Task createTaskWithFields(Id accountId, String subject, String priority, 
                                           String status, Date dueDate, Boolean doInsert) {
        Task task = new Task(
            Subject = subject,
            WhatId = accountId,
            Status = status,
            Priority = priority,
            ActivityDate = dueDate
        );
        
        if (doInsert) {
            insert task;
        }
        
        return task;
    }
}