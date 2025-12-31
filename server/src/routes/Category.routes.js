import express from 'express';
import { createCategory, deleteCategory, getAllCategories } from '../controllers/Category.controller.js';

const router = express.Router();

router.get('/', getAllCategories);
router.post('/', createCategory); // Add auth middleware if needed
router.delete('/:id', deleteCategory); // Add auth middleware if needed

export default router;
