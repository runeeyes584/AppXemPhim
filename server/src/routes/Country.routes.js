import express from 'express';
import { createCountry, deleteCountry, getAllCountries } from '../controllers/Country.controller.js';

const router = express.Router();

router.get('/', getAllCountries);
router.post('/', createCountry); // Add auth middleware if needed
router.delete('/:id', deleteCountry); // Add auth middleware if needed

export default router;
