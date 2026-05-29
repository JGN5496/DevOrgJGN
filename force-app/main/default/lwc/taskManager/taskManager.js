import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getTasks from '@salesforce/apex/TaskManagerController.getTasks';
import createTask from '@salesforce/apex/TaskManagerController.createTask';
import updateTaskStatus from '@salesforce/apex/TaskManagerController.updateTaskStatus';
import deleteTask from '@salesforce/apex/TaskManagerController.deleteTask';

/**
 * Quick Task Manager component for Account record pages.
 * Provides CRUD operations for tasks with inline editing and status management.
 */
export default class TaskManager extends LightningElement {
    @api recordId; // Account record ID from page context
    
    @track newTaskSubject = '';
    @track newTaskPriority = 'Normal';
    @track newTaskStatus = 'Not Started';
    @track newTaskDueDate = null;
    
    isLoading = false;
    wiredTasksResult;
    
    priorityOptions = [
        { label: 'High', value: 'High' },
        { label: 'Normal', value: 'Normal' },
        { label: 'Low', value: 'Low' }
    ];
    
    statusOptions = [
        { label: 'Not Started', value: 'Not Started' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Waiting on someone else', value: 'Waiting on someone else' },
        { label: 'Deferred', value: 'Deferred' }
    ];
    
    /**
     * Wire service to fetch tasks for the current Account
     */
    @wire(getTasks, { accountId: '$recordId' })
    wiredTasks(result) {
        this.wiredTasksResult = result;
        if (result.error) {
            this.showToast('Error', 'Error loading tasks: ' + result.error.body.message, 'error');
        }
    }
    
    /**
     * Get tasks from wired result
     */
    get tasks() {
        return this.wiredTasksResult?.data || [];
    }
    
    /**
     * Check if there are tasks to display
     */
    get hasTasks() {
        return this.tasks.length > 0;
    }
    
    /**
     * Check if the form is valid for submission
     */
    get isFormValid() {
        return this.newTaskSubject && this.newTaskSubject.trim().length > 0;
    }
    
    /**
     * Handle input changes for new task form
     */
    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        
        switch(field) {
            case 'subject':
                this.newTaskSubject = value;
                break;
            case 'priority':
                this.newTaskPriority = value;
                break;
            case 'status':
                this.newTaskStatus = value;
                break;
            case 'dueDate':
                this.newTaskDueDate = value;
                break;
            default:
                break;
        }
    }
    
    /**
     * Handle task creation
     */
    async handleCreateTask() {
        if (!this.isFormValid) {
            this.showToast('Error', 'Please enter a task subject', 'error');
            return;
        }
        
        this.isLoading = true;
        
        const task = {
            Subject: this.newTaskSubject,
            WhatId: this.recordId,
            Priority: this.newTaskPriority,
            Status: this.newTaskStatus,
            ActivityDate: this.newTaskDueDate
        };
        
        try {
            await createTask({ task });
            this.showToast('Success', 'Task created successfully', 'success');
            this.resetForm();
            await refreshApex(this.wiredTasksResult);
        } catch (error) {
            this.showToast('Error', 'Error creating task: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    /**
     * Handle task status toggle (complete/incomplete)
     */
    async handleStatusToggle(event) {
        const taskId = event.target.dataset.id;
        const isCompleted = event.target.checked;
        
        this.isLoading = true;
        
        try {
            await updateTaskStatus({ taskId, isCompleted });
            this.showToast('Success', 'Task status updated', 'success');
            await refreshApex(this.wiredTasksResult);
        } catch (error) {
            this.showToast('Error', 'Error updating task: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    /**
     * Handle task deletion
     */
    async handleDeleteTask(event) {
        const taskId = event.target.dataset.id;
        
        // Confirm deletion
        const confirmDelete = confirm('Are you sure you want to delete this task?');
        if (!confirmDelete) {
            return;
        }
        
        this.isLoading = true;
        
        try {
            await deleteTask({ taskId });
            this.showToast('Success', 'Task deleted successfully', 'success');
            await refreshApex(this.wiredTasksResult);
        } catch (error) {
            this.showToast('Error', 'Error deleting task: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    /**
     * Reset the form to default values
     */
    resetForm() {
        this.newTaskSubject = '';
        this.newTaskPriority = 'Normal';
        this.newTaskStatus = 'Not Started';
        this.newTaskDueDate = null;
    }
    
    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
    
    /**
     * Format date for display
     */
    formatDate(dateValue) {
        if (!dateValue) return '';
        const date = new Date(dateValue);
        return date.toLocaleDateString();
    }
}